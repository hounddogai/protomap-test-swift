import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Checks providers against the rules before anything acts on them.
final class ProviderValidationEndpoint: Acme_Appointments_V1_ProviderValidationService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>
    let searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>
    let telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>
    let telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>
    let telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    init(
        dependencies: any Dependencies,
        appointmentsAppointmentValidation: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        prescriptionsPrescriptionCalculation: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<
            MeshTransport
        >,
        searchSearchIndex: Acme_Search_V1_SearchIndexService.Client<MeshTransport>,
        telehealthVideoVisit: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>,
        telehealthVideoVisitCalculation: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>,
        telehealthVideoVisitValidation: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointmentValidation = appointmentsAppointmentValidation
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.documentsDocumentQuery = documentsDocumentQuery
        self.identityUser = identityUser
        self.prescriptionsPrescriptionCalculation = prescriptionsPrescriptionCalculation
        self.searchSearchIndex = searchSearchIndex
        self.telehealthVideoVisit = telehealthVideoVisit
        self.telehealthVideoVisitCalculation = telehealthVideoVisitCalculation
        self.telehealthVideoVisitValidation = telehealthVideoVisitValidation
    }
}
