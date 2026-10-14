import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientEndpoint {
    /// Execute the patients workflow and project its upstream replies.
    func processBatchCreatePatients(_ input: Acme_Patients_V1_BatchCreatePatientsRequest) async throws
        -> Acme_Patients_V1_BatchCreatePatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.header.format)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.header.format
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchCreatePatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "BatchCreatePatients", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_BatchCreatePrescriptionsRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescription.batchCreatePrescriptions { writer in
            try await writer.write(importFrame)
        }
        let selection0_1: Acme_Common_V1_PersonName
        switch input.chunk {
        case .record(let record):
            selection0_1 = record.contact.name
        default: selection0_1 = .init()
        }
        let outbound0 = Acme_Careplans_V1_QuoteCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = selection0_1
                }
            }
            $0.context = input.context
        }
        let reply0 = try await self.careplansCareGoalCalculation.quoteCareGoal(outbound0)
        let outbound1 = Acme_Telehealth_V1_QuoteTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careGoal.requester.email
                }
                $0.sla = Acme_Telehealth_V1_TriageSla.with {
                    $0.dueAt = reply0.careGoal.sla.dueAt
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Telehealth_V1_QuoteTriageResponse = {
            try await self.telehealthTriageCalculation.quoteTriage(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Patients_V1_BatchCreatePatientsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply0.result.message
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processBatchGetPatients(_ input: Acme_Patients_V1_BatchGetPatientsRequest) async throws
        -> Acme_Patients_V1_BatchGetPatientsResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BatchGetPatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "BatchGetPatients", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Authorization_V1_FindAccessPoliciesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Authorization_V1_FindAccessPoliciesRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.context.actor.userID
            }
        }
        let reply0 = try await self.authorizationAccessPolicyQuery.findAccessPolicies(outbound0)
        return Acme_Patients_V1_BatchGetPatientsResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processClonePatient(_ input: Acme_Patients_V1_ClonePatientRequest) async throws
        -> Acme_Patients_V1_ClonePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.patient.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.patient.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ClonePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_FindPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_FindPatientsRequest.Filter.with {
                $0.createdAfter = input.patient.audit.updatedAt
                $0.labels = input.patient.attributes
                $0.ownerID = input.patient.relationshipManager.userID
                $0.region = input.patient.primaryAddress.region
            }
        }
        async let remote0 = self.patientsPatientQuery.findPatients(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Patients_V1_ClonePatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.patient.name
                }
                $0.primaryAddress = input.patient.primaryAddress
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCreatePatient(_ input: Acme_Patients_V1_CreatePatientRequest) async throws
        -> Acme_Patients_V1_CreatePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.patient.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.patient.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CreatePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Appointments_V1_CountAppointmentsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_CountAppointmentsRequest.Filter.with {
                $0.createdAfter = input.patient.audit.createdAt
                $0.region = input.patient.primaryAddress.region
            }
        }
        let reply0 = try await self.createPatientStep0.execute(outbound0)
        let outbound1 = Acme_Patients_V1_PreviewPatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.patient.audit.etag
                    $0.updatedAt = input.patient.audit.updatedAt
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.patient.primaryAddress.countryCode
                }
            }
        }
        let port1 = RPCOperations.port { (request: Acme_Patients_V1_PreviewPatientRequest) in
            try await self.patientsPatientValidation.previewPatient(request)
        }
        let reply1 = try await port1.execute(outbound1)
        return Acme_Patients_V1_CreatePatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = reply1.patient.name
                }
                $0.patientID = input.patient.patientID
                $0.preferences = Acme_Patients_V1_PatientPreferences.with {
                    $0.marketingOptIn = reply1.patient.preferences.marketingOptIn
                }
                $0.primaryAddress = input.patient.primaryAddress
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processDeletePatient(_ input: Acme_Patients_V1_DeletePatientRequest) async throws
        -> Acme_Patients_V1_DeletePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.etag)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.etag
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "DeletePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "DeletePatient", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_PeekPatientRequest.with {
            $0.context = input.context
            $0.patientID = input.patientID
        }
        let reply0 = try await self.deletePatientStep0(outbound0)
        let selection1_2: Google_Protobuf_Timestamp
        switch reply0.patient.identityDocument {
        case .passport(let passport):
            selection1_2 = passport.expiresAt
        default: selection1_2 = .init()
        }
        let outbound1 = Acme_Patients_V1_CountPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_CountPatientsRequest.Filter.with {
                $0.createdAfter = selection1_2
                $0.labels = reply0.result.details
                $0.ownerID = reply0.patient.patientID
                $0.region = reply0.patient.primaryAddress.region
            }
        }
        let reply1 = try await self.patientsPatientQuery.countPatients(outbound1)
        return Acme_Patients_V1_DeletePatientResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply1.result.correlationID
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processGetPatient(_ input: Acme_Patients_V1_GetPatientRequest) async throws
        -> Acme_Patients_V1_GetPatientResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "GetPatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "GetPatient", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_LintMedicalRecordsRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.patientID = input.patientID
                }
            }
        }
        guard let execute0 = self.getPatientStep0[settings.region] ?? self.getPatientStep0["primary"] else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply0 = try await execute0(outbound0)
        return Acme_Patients_V1_GetPatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.medicalRecord.audit.createdBy
                }
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processListPatients(_ input: Acme_Patients_V1_ListPatientsRequest) async throws
        -> Acme_Patients_V1_ListPatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ListPatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "ListPatients", detail: input.context.traceID
        )
        let outbound0 = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
        let reply0 = try await self.patientsMedicalRecordCalculation.explainMedicalRecordCalculation(outbound0)
        let outbound1 = Acme_Prescriptions_V1_NormalizeMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply0.medicalRecord.billingAddress.countryCode
                    $0.region = reply0.medicalRecord.billingAddress.region
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.medicalRecord.audit.etag
                }
            }
        }
        let envelope1 = try Google_Protobuf_Any(message: outbound1)
        let unpacked1 = try Acme_Prescriptions_V1_NormalizeMedicationRequest(unpackingAny: envelope1)
        let reply1 = try await self.prescriptionsMedicationValidation.normalizeMedication(unpacked1)
        return Acme_Patients_V1_ListPatientsResponse.with {
            $0.patients = [
                Acme_Patients_V1_Patient.with {
                    $0.audit = Acme_Common_V1_AuditInfo.with {
                        $0.etag = reply1.medication.audit.etag
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = reply0.outcome.status
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSearchPatients(_ input: Acme_Patients_V1_SearchPatientsRequest) async throws
        -> Acme_Patients_V1_SearchPatientsResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SearchPatients",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "SearchPatients", detail: input.context.traceID
        )
        let outbound0 = Acme_Appointments_V1_ScoreProviderRequest.with {
            $0.context = input.context
            $0.details = Acme_Appointments_V1_ScoreProviderRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Appointments_V1_ScoreProviderRequest(jsonString: json0)
        let reply0 = try await self.appointmentsProviderValidation.scoreProvider(decoded0)
        let outbound1 = Acme_Patients_V1_FindPatientsRequest.forPatientEndpointSearchPatients1(
            input
        )
        let reply1 = try await self.patientsPatientQuery.findPatients(outbound1)
        return Acme_Patients_V1_SearchPatientsResponse.with {
            $0.pageInfo = Acme_Common_V1_PageInfo.with {
                $0.nextPageToken = reply1.pageInfo.nextPageToken
            }
            $0.patients = [
                Acme_Patients_V1_Patient.with {
                    $0.contact = Acme_Common_V1_ContactInfo.with {
                        $0.email = reply0.provider.relationshipManager.email
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.referenceIds = reply1.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processUpdatePatient(_ input: Acme_Patients_V1_UpdatePatientRequest) async throws
        -> Acme_Patients_V1_UpdatePatientResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.patient.audit.createdBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.patient.audit.createdBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "UpdatePatient",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Search_V1_FindSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_FindSearchIndexesRequest.Filter.with {
                $0.createdAfter = input.patient.audit.updatedAt
                $0.region = input.patient.primaryAddress.region
            }
        }
        let reply0 = try await self.searchSearchIndexQuery.findSearchIndexes(
            outbound0, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_UpdatePatientResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patient.patientID
                $0.status = input.patient.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }
}
