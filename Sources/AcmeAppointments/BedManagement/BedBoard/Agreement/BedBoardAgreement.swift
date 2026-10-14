import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board agreement is in its life cycle.
    enum BedBoardAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a bed board agreement and its current status.
    final class BedBoardAgreement {
        var code: String
        var label: String
        var attributes: [String: String]
        var contactEmail: String
        var refills: Int
        var patientRef: String
        var durationMinutes: Int
        var encounterID: String
        var name: String
        var status: BedBoardAgreementStatus

        init(code: String, label: String, attributes: [String: String], contactEmail: String, refills: Int, patientRef: String, durationMinutes: Int, encounterID: String, name: String, status: BedBoardAgreementStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.contactEmail = contactEmail
            self.refills = refills
            self.patientRef = patientRef
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardAgreementStatus) -> Bool {
            switch status {
            case .new:
                return next == BedBoardAgreementStatus.done || next == BedBoardAgreementStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == BedBoardAgreementStatus.done
            case .done:
                return next == BedBoardAgreementStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedLoad() -> Double {
            return ((Double(refills) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardAgreement {
            return BedBoardAgreement(
                code: code,
                label: label,
                attributes: attributes,
                contactEmail: contactEmail,
                refills: refills,
                patientRef: patientRef,
                durationMinutes: durationMinutes,
                encounterID: encounterID,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a bed board agreement in status new.
    static func newBedBoardAgreement(_ code: String, label: String) -> BedBoardAgreement {
        return BedBoardAgreement(
            code: code,
            label: label,
            attributes: [:],
            contactEmail: "",
            refills: 0,
            patientRef: "",
            durationMinutes: 0,
            encounterID: "",
            name: "",
            status: BedBoardAgreementStatus.new
        )
    }
}
