import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension VitalReportingEndpoint {
    /// Counts vitals by status.
    func countVitalTotals(
        request: ServerRequest<Acme_Careplans_V1_CountVitalTotalsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_CountVitalTotalsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processCountVitalTotals(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Deletes a vital.
    func deleteVitalReport(
        request: ServerRequest<Acme_Careplans_V1_DeleteVitalReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_DeleteVitalReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processDeleteVitalReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Returns a vital.
    func fetchVitalReport(
        request: ServerRequest<Acme_Careplans_V1_FetchVitalReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_FetchVitalReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processFetchVitalReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Generates a vital.
    func generateVitalReport(
        request: ServerRequest<Acme_Careplans_V1_GenerateVitalReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_GenerateVitalReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processGenerateVitalReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Lists vitals a page at a time.
    func listVitalReports(
        request: ServerRequest<Acme_Careplans_V1_ListVitalReportsRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ListVitalReportsResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processListVitalReports(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Schedules a vital.
    func scheduleVitalReport(
        request: ServerRequest<Acme_Careplans_V1_ScheduleVitalReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ScheduleVitalReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processScheduleVitalReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Shares a vital.
    func shareVitalReport(
        request: ServerRequest<Acme_Careplans_V1_ShareVitalReportRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Acme_Careplans_V1_ShareVitalReportResponse> {
        return try await CallerScope.$metadata.withValue(request.metadata) {
            let response = try await processShareVitalReport(request.message)
            return ServerResponse(message: response)
        }
    }

    /// Streams the changes of vitals as they happen.
    func streamVitalMetrics(
        request: ServerRequest<Acme_Careplans_V1_StreamVitalMetricsRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Acme_Careplans_V1_StreamVitalMetricsResponse> {
        return StreamingServerResponse { writer in
            try await CallerScope.$metadata.withValue(request.metadata) {
                let response = try await self.processStreamVitalMetrics(request.message)
                try await writer.write(response)
                return [:]
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processCountVitalTotals(_ input: Acme_Careplans_V1_CountVitalTotalsRequest) async throws
        -> Acme_Careplans_V1_CountVitalTotalsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountVitalTotals",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "CountVitalTotals", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Patients_V1_BatchCreatePatientsRequest.with {
            $0.context = input.context
        }
        _ = try await self.patientsPatient.batchCreatePatients { writer in
            try await writer.write(importFrame)
        }
        let outbound0 = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = Projection.read(input, at: \Acme_Careplans_V1_CountVitalTotalsRequest.context)
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = Projection.read(input, at: \Acme_Careplans_V1_CountVitalTotalsRequest.filter.region)
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = Projection.read(
                        input, at: \Acme_Careplans_V1_CountVitalTotalsRequest.context.actor.email)
                }
            }
        }
        let reply0 = try await self.patientsMedicalRecordCalculation.explainMedicalRecordCalculation(outbound0)
        return Acme_Careplans_V1_CountVitalTotalsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processDeleteVitalReport(_ input: Acme_Careplans_V1_DeleteVitalReportRequest) async throws
        -> Acme_Careplans_V1_DeleteVitalReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.etag
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeleteVitalReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "DeleteVitalReport", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Notifications_V1_BatchGetNotificationsRequest.with {
            $0.context = input.context
        }
        let step0: @Sendable () async throws -> Acme_Notifications_V1_BatchGetNotificationsResponse = {
            try await self.notificationsNotification.batchGetNotifications(outbound0)
        }
        let reply0 = try await step0()
        var outbound1 = Acme_Careplans_V1_ScheduleCarePlanExpiryRequest()
        outbound1.context = input.context
        outbound1.reason = input.reason
        let reply1 = try await self.careplansCarePlanLifecycle.scheduleCarePlanExpiry(outbound1)
        return Acme_Careplans_V1_DeleteVitalReportResponse.with {
            $0.effectiveAt = reply1.outcome.effectiveAt
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processFetchVitalReport(_ input: Acme_Careplans_V1_FetchVitalReportRequest) async throws
        -> Acme_Careplans_V1_FetchVitalReportResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FetchVitalReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "FetchVitalReport", detail: input.context.traceID
        )
        return Acme_Careplans_V1_FetchVitalReportResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processGenerateVitalReport(_ input: Acme_Careplans_V1_GenerateVitalReportRequest) async throws
        -> Acme_Careplans_V1_GenerateVitalReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GenerateVitalReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "GenerateVitalReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_SimulateCareGoalRequest.with {
            $0.context = input.context
            $0.reason = input.reason
        }
        let step0: @Sendable () async throws -> Acme_Careplans_V1_SimulateCareGoalResponse = {
            try await self.careplansCareGoalCalculation.simulateCareGoal(outbound0)
        }
        let reply0 = try await step0()
        let outbound1 = Acme_Careplans_V1_SimulateVitalRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SimulateVitalRequest.Details.with {
                $0.currencyCode = reply0.breakdown.currencyCode
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply0.result.correlationID
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply0.careGoal.assignee.displayName
                }
            }
        }
        let reply1 = try await self.careplansVitalCalculation.simulateVital(outbound1)
        let outbound2 = Acme_Appointments_V1_ExplainClinicSlotDecisionRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.careGoal.audit.createdBy
                }
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.careGoal.assignee.email
                            $0.phone = reply0.careGoal.requester.phone
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        async let remote2 = self.appointmentsClinicSlotValidation.explainClinicSlotDecision(outbound2)
        async let persisted2 = store.count(tenant: input.context.tenantID)
        let (reply2, count2) = try await (remote2, persisted2)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count2)])
        let selection3_3: String
        switch reply0.careGoal.origin {
        case .customer(let customer):
            selection3_3 = customer.email
        default: selection3_3 = .init()
        }
        let outbound3 = Acme_Prescriptions_V1_PreviewMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply2.clinicSlot.location.postalCode
                    $0.recipient = reply2.clinicSlot.location.recipient
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = selection3_3
                    $0.userID = reply0.careGoal.assignee.userID
                }
            }
        }
        let reply3 = try await self.prescriptionsMedicationValidation.previewMedication(outbound3)
        return Acme_Careplans_V1_GenerateVitalReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply1.result.correlationID,
                        reply2.result.correlationID,
                    ], default: .init())
                $0.details = reply3.result.details
                $0.status = Projection.firstValue(
                    [
                        reply0.result.status,
                        reply2.result.status,
                    ], default: .init())
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processListVitalReports(_ input: Acme_Careplans_V1_ListVitalReportsRequest) async throws
        -> Acme_Careplans_V1_ListVitalReportsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListVitalReports",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "ListVitalReports", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_LintVitalsRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_LintVitalsRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                    $0.startsAt = input.filter.createdAfter
                }
            }
        }
        let reply0 = try await self.listVitalReportsStep0.execute(outbound0)
        return Acme_Careplans_V1_ListVitalReportsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.vital.correlationID
                $0.status = "ok"
            }
            $0.vitals = [
                Acme_Careplans_V1_Vital.with {
                    $0.subject = Acme_Appointments_V1_AppointmentRef.with {
                        $0.displayName = reply0.vital.subject.displayName
                    }
                }
            ]
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processScheduleVitalReport(_ input: Acme_Careplans_V1_ScheduleVitalReportRequest) async throws
        -> Acme_Careplans_V1_ScheduleVitalReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.cron)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.cron
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ScheduleVitalReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "ScheduleVitalReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_PreviewPrescriptionRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_PreviewPrescriptionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
            $0.reason = input.reason
        }
        let port0 = RPCOperations.port { (request: Acme_Prescriptions_V1_PreviewPrescriptionRequest) in
            try await self.prescriptionsPrescriptionValidation.previewPrescription(request)
        }
        let reply0 = try await port0.execute(outbound0)
        let outbound1 = Acme_Appointments_V1_CloneAppointmentRequest.with {
            $0.appointment = Acme_Appointments_V1_Appointment.with {
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.lines = reply0.prescription.billingAddress.lines
                    $0.locality = reply0.prescription.billingAddress.locality
                }
                $0.participants = [
                    Acme_Appointments_V1_AppointmentParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.prescription.counterparty.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
        let reply1 = try await self.scheduleVitalReportStep1(outbound1)
        return Acme_Careplans_V1_ScheduleVitalReportResponse.with {
            $0.period = input.details.period
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply1.result.message
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processShareVitalReport(_ input: Acme_Careplans_V1_ShareVitalReportRequest) async throws
        -> Acme_Careplans_V1_ShareVitalReportResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.channel)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.details.channel
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ShareVitalReport",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "ShareVitalReport", detail: input.context.traceID
        )
        let outbound0 = Acme_Careplans_V1_CalculateCarePlanRequest.with {
            $0.annotations = input.annotations
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.context.deadline
                }
                $0.metadata = input.details.variables
            }
            $0.context = input.context
            $0.reason = input.reason
        }
        guard let execute0 = self.shareVitalReportStep0[settings.region] ?? self.shareVitalReportStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        let outbound1 = Acme_Venues_V1_SuggestVenuesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Venues_V1_SuggestVenuesRequest.Filter.with {
                $0.createdAfter = reply0.carePlan.counterparty.startsAt
                $0.region = reply0.carePlan.billingAddress.region
            }
        }
        let reply1 = try await self.venuesVenueQuery.suggestVenues(outbound1)
        return Acme_Careplans_V1_ShareVitalReportResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.vitalID = input.vitalID
            }
        }
    }

    /// Execute the careplans workflow and project its upstream replies.
    func processStreamVitalMetrics(_ input: Acme_Careplans_V1_StreamVitalMetricsRequest) async throws
        -> Acme_Careplans_V1_StreamVitalMetricsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StreamVitalMetrics",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "vital",
            action: "StreamVitalMetrics", detail: input.context.traceID
        )
        let outbound0 = Acme_Ledger_V1_CreateLedgerAccountRequest.with {
            $0.context = input.context
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.subscriber.name
                    $0.phone = input.subscriber.phone
                    $0.preferredChannel = input.subscriber.preferredChannel
                }
                $0.labels = input.filter.labels
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Ledger_V1_CreateLedgerAccountRequest(unpackingAny: envelope0)
        let reply0 = try await self.ledgerLedgerAccount.createLedgerAccount(unpacked0)
        return Acme_Careplans_V1_StreamVitalMetricsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = reply0.result.status
            }
            $0.vital = Acme_Careplans_V1_Vital.with {
                $0.correlationID = reply0.result.correlationID
            }
        }
    }
}
