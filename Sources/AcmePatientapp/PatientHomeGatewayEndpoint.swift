import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// The edge API that apps call for patient homes.
final class PatientHomeGatewayEndpoint: Acme_Patientapp_V1_PatientHomeGatewayService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let itsmIncident: Acme_Itsm_V1_IncidentService.Client<MeshTransport>
    let metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>
    let notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let patientappCareInboxQuery: Acme_Patientapp_V1_CareInboxQueryService.Client<MeshTransport>
    let patientappPatientHome: Acme_Patientapp_V1_PatientHomeService.Client<MeshTransport>
    let patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client<MeshTransport>
    let patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>
    let patientsAllergyWorkflow: Acme_Patients_V1_AllergyWorkflowService.Client<MeshTransport>
    let patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>
    let prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>
    let sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>
    let venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    let uploadPatientHomeAttachmentsStep2:
        any RPCPort<
            Acme_Patientapp_V1_AcknowledgePatientHomeEventRequest,
            Acme_Patientapp_V1_AcknowledgePatientHomeEventResponse
        >

    init(
        dependencies: any Dependencies,
        careplansCareGoalWorkflow: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        itsmIncident: Acme_Itsm_V1_IncidentService.Client<MeshTransport>,
        metricsMetricSeriesValidation: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>,
        notificationsNotificationQuery: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        patientappCareInboxQuery: Acme_Patientapp_V1_CareInboxQueryService.Client<MeshTransport>,
        patientappPatientHome: Acme_Patientapp_V1_PatientHomeService.Client<MeshTransport>,
        patientappPatientHomeIntegration: Acme_Patientapp_V1_PatientHomeIntegrationService.Client<MeshTransport>,
        patientappPatientHomeWorkflow: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>,
        patientsAllergyWorkflow: Acme_Patients_V1_AllergyWorkflowService.Client<MeshTransport>,
        patientsPatientWorkflow: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>,
        prescriptionsRefillWorkflow: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>,
        sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>,
        venuesVenueValidation: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.careplansCareGoalWorkflow = careplansCareGoalWorkflow
        self.identityUser = identityUser
        self.itsmIncident = itsmIncident
        self.metricsMetricSeriesValidation = metricsMetricSeriesValidation
        self.notificationsNotificationQuery = notificationsNotificationQuery
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.patientappCareInboxQuery = patientappCareInboxQuery
        self.patientappPatientHome = patientappPatientHome
        self.patientappPatientHomeIntegration = patientappPatientHomeIntegration
        self.patientappPatientHomeWorkflow = patientappPatientHomeWorkflow
        self.patientsAllergyWorkflow = patientsAllergyWorkflow
        self.patientsPatientWorkflow = patientsPatientWorkflow
        self.prescriptionsRefillWorkflow = prescriptionsRefillWorkflow
        self.sponsorshipsSponsorQuery = sponsorshipsSponsorQuery
        self.venuesVenueValidation = venuesVenueValidation
        self.uploadPatientHomeAttachmentsStep2 = ClosurePort<
            Acme_Patientapp_V1_AcknowledgePatientHomeEventRequest,
            Acme_Patientapp_V1_AcknowledgePatientHomeEventResponse
        >({ request in try await patientappPatientHomeIntegration.acknowledgePatientHomeEvent(request) })
    }

    /// Composes a patient home.
    func composePatientHomePage(
        request: ServerRequest<Acme_Patientapp_V1_ComposePatientHomePageRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_ComposePatientHomePageResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processComposePatientHomePage(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Fetchs a patient home.
    func fetchPatientHomeView(
        request: ServerRequest<Acme_Patientapp_V1_FetchPatientHomeViewRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_FetchPatientHomeViewResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFetchPatientHomeView(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a patient home.
    func getPatientHomeSummary(
        request: ServerRequest<Acme_Patientapp_V1_GetPatientHomeSummaryRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_GetPatientHomeSummaryResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGetPatientHomeSummary(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Refreshs a patient home.
    func refreshPatientHome(
        request: ServerRequest<Acme_Patientapp_V1_RefreshPatientHomeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_RefreshPatientHomeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processRefreshPatientHome(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists patient homes a page at a time.
    func searchPatientHomeCatalog(
        request: ServerRequest<Acme_Patientapp_V1_SearchPatientHomeCatalogRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SearchPatientHomeCatalogResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSearchPatientHomeCatalog(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Starts a patient home.
    func startPatientHomeCheckout(
        request: ServerRequest<Acme_Patientapp_V1_StartPatientHomeCheckoutRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_StartPatientHomeCheckoutResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processStartPatientHomeCheckout(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Submits a patient home.
    func submitPatientHomeForm(
        request: ServerRequest<Acme_Patientapp_V1_SubmitPatientHomeFormRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_SubmitPatientHomeFormResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSubmitPatientHomeForm(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Tracks a patient home.
    func trackPatientHome(
        request: ServerRequest<Acme_Patientapp_V1_TrackPatientHomeRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_TrackPatientHomeResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processTrackPatientHome(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Takes a stream of patient homes and answers once at the end.
    func uploadPatientHomeAttachments(
        request: StreamingServerRequest<Acme_Patientapp_V1_UploadPatientHomeAttachmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Patientapp_V1_UploadPatientHomeAttachmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            var response = Acme_Patientapp_V1_UploadPatientHomeAttachmentsResponse()
            var accepted: Int64 = 0
            for try await message in request.messages {
                response = try await processUploadPatientHomeAttachments(message)
                accepted += 1
            }
            response.accepted = accepted
            return ServerResponse(message: response)
        }
    }
}
