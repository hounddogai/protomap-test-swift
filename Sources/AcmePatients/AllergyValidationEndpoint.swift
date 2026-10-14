import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks allergies against the rules before anything acts on them.
final class AllergyValidationEndpoint: Acme_Patients_V1_AllergyValidationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    let boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>
    let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>
    let previewAllergyStep0:
        any RPCPort<Acme_Sponsorships_V1_SimulateSponsorRequest, Acme_Sponsorships_V1_SimulateSponsorResponse>
    let scoreAllergyStep1:
        @Sendable (Acme_Patients_V1_NormalizePatientRequest) async throws -> Acme_Patients_V1_NormalizePatientResponse
    let scoreAllergyStep2:
        [String:
            @Sendable (Acme_Authorization_V1_LintAccessPoliciesRequest) async throws ->
            Acme_Authorization_V1_LintAccessPoliciesResponse]

    init(
        dependencies: any Dependencies,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        boxofficeBoxOfficeSaleCalculation: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        patientsAllergyCalculation: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatientValidation: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        sponsorshipsSponsorCalculation: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.boxofficeBoxOfficeSaleCalculation = boxofficeBoxOfficeSaleCalculation
        self.documentsDocumentValidation = documentsDocumentValidation
        self.identityUser = identityUser
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.patientsAllergyCalculation = patientsAllergyCalculation
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatientValidation = patientsPatientValidation
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescription = prescriptionsPrescription
        self.sponsorshipsSponsorCalculation = sponsorshipsSponsorCalculation
        self.previewAllergyStep0 = ClosurePort<
            Acme_Sponsorships_V1_SimulateSponsorRequest, Acme_Sponsorships_V1_SimulateSponsorResponse
        >({ request in try await sponsorshipsSponsorCalculation.simulateSponsor(request) })
        self.scoreAllergyStep1 = { request in try await patientsPatientValidation.normalizePatient(request) }
        self.scoreAllergyStep2 = [
            "primary": { request in try await authorizationAccessPolicyValidation.lintAccessPolicies(request) }
        ]
    }

    /// Checks an allergy.
    func checkAllergyEligibility(
        request: ServerRequest<Acme_Patients_V1_CheckAllergyEligibilityRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_CheckAllergyEligibilityResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCheckAllergyEligibility(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an allergy.
    func getAllergyRules(
        request: ServerRequest<Acme_Patients_V1_GetAllergyRulesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_GetAllergyRulesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetAllergyRules(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lints an allergy.
    func lintAllergies(
        request: ServerRequest<Acme_Patients_V1_LintAllergiesRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_LintAllergiesResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLintAllergies(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Normalizes an allergy.
    func normalizeAllergy(
        request: ServerRequest<Acme_Patients_V1_NormalizeAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_NormalizeAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processNormalizeAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Previews an allergy.
    func previewAllergy(
        request: ServerRequest<Acme_Patients_V1_PreviewAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_PreviewAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPreviewAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Scores an allergy.
    func scoreAllergy(
        request: ServerRequest<Acme_Patients_V1_ScoreAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ScoreAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScoreAllergy(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Validates an allergy.
    func validateAllergy(
        request: ServerRequest<Acme_Patients_V1_ValidateAllergyRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patients_V1_ValidateAllergyResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processValidateAllergy(request.message)
            return ServerResponse(message: response)
        }
    }
}
