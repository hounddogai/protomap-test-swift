import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

/// Builds and schedules reports about vitals.
final class VitalReportingEndpoint: Acme_Careplans_V1_VitalReportingService.ServiceProtocol {
    let store: any RecordRepository
    let logger: Logger
    let settings: Settings
    let directory = ActorDirectory()
    let appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>
    let appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>
    let careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>
    let careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>
    let careplansCarePlanLifecycle: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>
    let careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>
    let careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>
    let identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>
    let ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>
    let notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>
    let patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>
    let patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>
    let prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>
    let prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>
    let venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    let listVitalReportsStep0: any RPCPort<Acme_Careplans_V1_LintVitalsRequest, Acme_Careplans_V1_LintVitalsResponse>
    let scheduleVitalReportStep1:
        @Sendable (Acme_Appointments_V1_CloneAppointmentRequest) async throws ->
            Acme_Appointments_V1_CloneAppointmentResponse
    let shareVitalReportStep0:
        [String:
            @Sendable (Acme_Careplans_V1_CalculateCarePlanRequest) async throws ->
            Acme_Careplans_V1_CalculateCarePlanResponse]

    init(
        dependencies: any Dependencies,
        appointmentsAppointment: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>,
        appointmentsClinicSlotValidation: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>,
        careplansCareGoalCalculation: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>,
        careplansCarePlanCalculation: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>,
        careplansCarePlanLifecycle: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>,
        careplansVitalCalculation: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>,
        careplansVitalValidation: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>,
        identityUser: Acme_Identity_V1_UserService.Client<MeshTransport>,
        ledgerLedgerAccount: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>,
        notificationsNotification: Acme_Notifications_V1_NotificationService.Client<MeshTransport>,
        patientsMedicalRecordCalculation: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>,
        patientsPatient: Acme_Patients_V1_PatientService.Client<MeshTransport>,
        prescriptionsMedicationValidation: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>,
        prescriptionsPrescriptionValidation: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>,
        venuesVenueQuery: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>
    ) {
        self.store = dependencies.repository
        self.logger = dependencies.logger
        self.settings = dependencies.settings
        self.appointmentsAppointment = appointmentsAppointment
        self.appointmentsClinicSlotValidation = appointmentsClinicSlotValidation
        self.careplansCareGoalCalculation = careplansCareGoalCalculation
        self.careplansCarePlanCalculation = careplansCarePlanCalculation
        self.careplansCarePlanLifecycle = careplansCarePlanLifecycle
        self.careplansVitalCalculation = careplansVitalCalculation
        self.careplansVitalValidation = careplansVitalValidation
        self.identityUser = identityUser
        self.ledgerLedgerAccount = ledgerLedgerAccount
        self.notificationsNotification = notificationsNotification
        self.patientsMedicalRecordCalculation = patientsMedicalRecordCalculation
        self.patientsPatient = patientsPatient
        self.prescriptionsMedicationValidation = prescriptionsMedicationValidation
        self.prescriptionsPrescriptionValidation = prescriptionsPrescriptionValidation
        self.venuesVenueQuery = venuesVenueQuery
        self.listVitalReportsStep0 = ClosurePort<
            Acme_Careplans_V1_LintVitalsRequest, Acme_Careplans_V1_LintVitalsResponse
        >({ request in try await careplansVitalValidation.lintVitals(request) })
        self.scheduleVitalReportStep1 = { request in try await appointmentsAppointment.cloneAppointment(request) }
        self.shareVitalReportStep0 = [
            "primary": { request in try await careplansCarePlanCalculation.calculateCarePlan(request) }
        ]
    }
}
