import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Manages care plans: creates, reads, changes, and lists them.
final class CarePlanEndpoint: Acme_Careplans_V1_CarePlanService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let admissionsAdmissionQuery: Acme_Admissions_V1_AdmissionQueryService.Client<MeshTransport>
    let authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>
    let authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    let careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>
    let careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>
    let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    let documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>
    let documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>
    let sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>
    let getCarePlanStep0:
        any RPCPort<Acme_Careplans_V1_SimulateCarePlanRequest, Acme_Careplans_V1_SimulateCarePlanResponse>
    let listCarePlansStep0:
        @Sendable (Acme_Careplans_V1_EstimateCareGoalRequest) async throws -> Acme_Careplans_V1_EstimateCareGoalResponse
    let updateCarePlanStep0:
        [String:
            @Sendable (Acme_Careplans_V1_BrowseCarePlansRequest) async throws ->
            Acme_Careplans_V1_BrowseCarePlansResponse]

    init(
        dependencies: any Dependencies,
        admissionsAdmissionQuery: Acme_Admissions_V1_AdmissionQueryService.Client<MeshTransport>,
        authorizationAccessPolicy: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>,
        authorizationAccessPolicyValidation: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanQuery: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>,
        careplansCarePlanValidation: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        documentsDocumentQuery: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>,
        documentsDocumentValidation: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccountQuery: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>,
        sponsorshipsSponsorQuery: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.admissionsAdmissionQuery = admissionsAdmissionQuery
        self.authorizationAccessPolicy = authorizationAccessPolicy
        self.authorizationAccessPolicyValidation = authorizationAccessPolicyValidation
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanQuery = careplansCarePlanQuery
        self.careplansCarePlanValidation = careplansCarePlanValidation
        self.careplansVitalCalculation = careplansVitalCalculation
        self.documentsDocumentQuery = documentsDocumentQuery
        self.documentsDocumentValidation = documentsDocumentValidation
        self.identityUser = identityUser
        self.ledgerLedgerAccountQuery = ledgerLedgerAccountQuery
        self.sponsorshipsSponsorQuery = sponsorshipsSponsorQuery
        self.getCarePlanStep0 = ClosurePort<
            Acme_Careplans_V1_SimulateCarePlanRequest, Acme_Careplans_V1_SimulateCarePlanResponse
        >({ request in try await careplansCarePlanCalculation.simulateCarePlan(request) })
        self.listCarePlansStep0 = { request in try await careplansCareGoalCalculation.estimateCareGoal(request) }
        self.updateCarePlanStep0 = ["primary": { request in try await careplansCarePlanQuery.browseCarePlans(request) }]
    }
}
