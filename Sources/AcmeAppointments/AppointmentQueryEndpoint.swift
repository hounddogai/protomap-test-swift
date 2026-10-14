import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Answers read-only questions about appointments, for screens and reports.
final class AppointmentQueryEndpoint: Acme_Appointments_V1_AppointmentQueryService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>
    let appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>
    let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>
    let performersPerformerQuery: Acme_Performers_V1_PerformerQueryService.Client<MeshTransport>
    let prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>
    let seatingSeatMap: Acme_Seating_V1_SeatMapService.Client<MeshTransport>
    let suggestAppointmentsStep0:
        any RPCPort<
            Acme_Appointments_V1_ExplainClinicSlotCalculationRequest,
            Acme_Appointments_V1_ExplainClinicSlotCalculationResponse
        >
    let summarizeAppointmentsStep0:
        @Sendable (Acme_Careplans_V1_CreateCarePlanRequest) async throws -> Acme_Careplans_V1_CreateCarePlanResponse
    let summarizeAppointmentsStep1:
        [String:
            @Sendable (Acme_Appointments_V1_RecalculateClinicSlotsRequest) async throws ->
            Acme_Appointments_V1_RecalculateClinicSlotsResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>,
        appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlan: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        notificationsNotificationValidation: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>,
        performersPerformerQuery: Acme_Performers_V1_PerformerQueryService.Client<MeshTransport>,
        prescriptionsPrescription: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>,
        seatingSeatMap: Acme_Seating_V1_SeatMapService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentValidation = appointmentsAppointmentValidation
        self.appointmentsClinicSlotCalculation = appointmentsClinicSlotCalculation
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlan = careplansCarePlan
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.identityUser = identityUser
        self.notificationsNotificationValidation = notificationsNotificationValidation
        self.performersPerformerQuery = performersPerformerQuery
        self.prescriptionsPrescription = prescriptionsPrescription
        self.seatingSeatMap = seatingSeatMap
        self.suggestAppointmentsStep0 = ClosurePort<
            Acme_Appointments_V1_ExplainClinicSlotCalculationRequest,
            Acme_Appointments_V1_ExplainClinicSlotCalculationResponse
        >({ request in try await appointmentsClinicSlotCalculation.explainClinicSlotCalculation(request) })
        self.summarizeAppointmentsStep0 = { request in try await careplansCarePlan.createCarePlan(request) }
        self.summarizeAppointmentsStep1 = [
            "primary": { request in try await appointmentsClinicSlotCalculation.recalculateClinicSlots(request) }
        ]
    }

    /// Lists appointments a page at a time.
    func browseAppointments(
        request: ServerRequest<Acme_Appointments_V1_BrowseAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_BrowseAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processBrowseAppointments(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Counts appointments by status.
    func countAppointments(
        request: ServerRequest<Acme_Appointments_V1_CountAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_CountAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountAppointments(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams every matching appointment.
    func exportAppointments(
        request: ServerRequest<Acme_Appointments_V1_ExportAppointmentsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Appointments_V1_ExportAppointmentsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processExportAppointments(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Lists appointments a page at a time.
    func findAppointments(
        request: ServerRequest<Acme_Appointments_V1_FindAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_FindAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFindAppointments(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an appointment.
    func lookupAppointment(
        request: ServerRequest<Acme_Appointments_V1_LookupAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_LookupAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processLookupAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns an appointment.
    func peekAppointment(
        request: ServerRequest<Acme_Appointments_V1_PeekAppointmentRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_PeekAppointmentResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processPeekAppointment(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns several appointments at once.
    func resolveAppointments(
        request: ServerRequest<Acme_Appointments_V1_ResolveAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_ResolveAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processResolveAppointments(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists appointments a page at a time.
    func suggestAppointments(
        request: ServerRequest<Acme_Appointments_V1_SuggestAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_SuggestAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSuggestAppointments(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Summarizes an appointment.
    func summarizeAppointments(
        request: ServerRequest<Acme_Appointments_V1_SummarizeAppointmentsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Appointments_V1_SummarizeAppointmentsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processSummarizeAppointments(request.message)
            return ServerResponse(message: response)
        }
    }
}
