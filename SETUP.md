# 🔑 Guía de Configuración: Terraform + GCP

## Opción 1: Setup Automático (Recomendado) ⭐

### En Linux/Mac:
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### En Windows (PowerShell):
```powershell
.\scripts\setup.ps1
```

**Este script:**
- ✅ Detecta si tienes gcloud y Terraform instalados
- ✅ **Los instala automáticamente** si no los tienes (usando winget, chocolatey, apt, yum, o brew)
- ✅ Te guía paso a paso para autenticarte con GCP
- ✅ Configura todo lo necesario

**Nota:** En Windows, el script intenta usar `winget` (incluido en Windows 10/11) o `chocolatey` si está disponible. Si ninguno funciona, te dará instrucciones para instalación manual.

---

## Opción 2: Setup Manual

### Paso 1: Instalar herramientas

1. **gcloud CLI**: https://cloud.google.com/sdk/docs/install
2. **Terraform**: https://developer.hashicorp.com/terraform/downloads

### Paso 2: Autenticarse con GCP

```bash
# Login interactivo (abre el navegador)
gcloud auth login

# Configurar Application Default Credentials (para Terraform)
gcloud auth application-default login

# Configurar tu proyecto
gcloud config set project <TU_PROJECT_ID>
```

---

## 🔐 ¿Dónde obtener las credenciales/llaves?

### **NO necesitas descargar una key JSON manualmente** si usas el método anterior.

El comando `gcloud auth application-default login` crea automáticamente las credenciales que Terraform necesita en:
- **Linux/Mac**: `~/.config/gcloud/application_default_credentials.json`
- **Windows**: `%APPDATA%\gcloud\application_default_credentials.json`

Terraform las detecta automáticamente.

---

## 🔑 Alternativa: Service Account Key (Para CI/CD o servidores)

Si necesitas usar una **Service Account Key JSON** (por ejemplo, para CI/CD):

### 1. Crear Service Account en GCP Console:

1. Ve a: https://console.cloud.google.com/iam-admin/serviceaccounts
2. Selecciona tu proyecto
3. Click en **"+ CREATE SERVICE ACCOUNT"**
4. Nombre: `terraform-deployer` (o el que prefieras)
5. Click **"CREATE AND CONTINUE"**

### 2. Asignar permisos:

En el paso de permisos, asigna estos roles:
- `Editor` (o más específicos: `Cloud Run Admin`, `API Gateway Admin`, `Artifact Registry Admin`, `Datastore Admin`, `Service Account User`)

Click **"CONTINUE"** → **"DONE"**

### 3. Crear y descargar la Key:

1. Click en el service account que acabas de crear
2. Ve a la pestaña **"KEYS"**
3. Click **"ADD KEY"** → **"Create new key"**
4. Selecciona **JSON**
5. Click **"CREATE"** (se descargará un archivo JSON)

### 4. Usar la key con Terraform:

**Opción A: Variable de entorno (Recomendado)**
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/ruta/al/archivo.json"
terraform apply -var="project_id=<PROJECT_ID>"
```

**Opción B: En providers.tf (No recomendado para producción)**
```hcl
provider "google" {
  credentials = file("/ruta/al/archivo.json")
  project     = var.project_id
  region      = var.region
}
```

---

## ✅ Verificar que todo funciona

```bash
# Verificar autenticación
gcloud auth list

# Verificar proyecto actual
gcloud config get-value project

# Probar Terraform
cd infra
terraform init
terraform plan -var="project_id=<TU_PROJECT_ID>"
```

---

## 🚨 Permisos necesarios

Tu cuenta de GCP necesita estos permisos (o el rol `Editor`):
- `run.admin` - Para Cloud Run
- `apigateway.admin` - Para API Gateway
- `artifactregistry.admin` - Para Artifact Registry
- `datastore.admin` - Para Firestore
- `iam.serviceAccountUser` - Para crear service accounts
- `servicemanagement.admin` - Para habilitar APIs

O simplemente el rol **`Editor`** en el proyecto.

---

## 📝 Resumen rápido

**Para desarrollo local (lo más simple):**
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
```

**Para CI/CD o servidores:**
1. Crear Service Account en GCP Console
2. Descargar key JSON
3. Usar variable `GOOGLE_APPLICATION_CREDENTIALS`

¡Listo! 🎉
