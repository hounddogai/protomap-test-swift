import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Manages appointments: creates, reads, changes, and lists them.
final class AppointmentEndpoint: Acme_Appointments_V1_AppointmentService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let followUps = WorkQueue<Acme_Identity_V1_GetUserRequest>()
    let appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>
    let appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>
    let appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>
    let appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>
    let appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>
    let featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>
    let showsShowQuery: Acme_Shows_V1_ShowQueryService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentQuery: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>,
        appointmentsClinicSlotCalculation: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>,
        appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>,
        appointmentsProviderQuery: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>,
        appointmentsProviderValidation: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>,
        featureflagsFeatureFlagValidation: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        prescriptionsMedicationQuery: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>,
        showsShowQuery: Acme_Shows_V1_ShowQueryService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentQuery = appointmentsAppointmentQuery
        self.appointmentsClinicSlotCalculation = appointmentsClinicSlotCalculation
        self.appointmentsClinicSlotValidation = appointmentsClinicSlotValidation
        self.appointmentsProviderQuery = appointmentsProviderQuery
        self.appointmentsProviderValidation = appointmentsProviderValidation
        self.featureflagsFeatureFlagValidation = featureflagsFeatureFlagValidation
        self.identityUser = identityUser
        self.prescriptionsMedicationQuery = prescriptionsMedicationQuery
        self.showsShowQuery = showsShowQuery
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
    }

    /// Resolve follow-up ownership outside the RPC's lifetime.
    func runFollowUps() async throws {
        for await event in followUps.events {
            try Task.checkCancellation()
            do {
                let user = try await self.identityUser.getUser(event)
                logger.info("Follow-up resolved", metadata: ["user": .string(user.user.userID)])
            } catch {
                logger.error("Follow-up failed", metadata: ["error": .string(String(describing: error))])
            }
        }
    }
}
