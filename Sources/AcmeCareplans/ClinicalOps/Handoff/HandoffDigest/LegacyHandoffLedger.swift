import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy handoff ledger is in its life cycle.
    enum LegacyHandoffLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy handoff ledger. Its code is unique within a tenant.
    final class LegacyHandoffLedger {
        var code: String
        var label: String
        var specialty: String
        var approved: Bool
        var diagnosisCode: String
        var title: String
        var ratio: Double
        var notes: String
        var active: Bool
        var timezone: String
        var status: LegacyHandoffLedgerStatus

        init(code: String, label: String, specialty: String, approved: Bool, diagnosisCode: String, title: String, ratio: Double, notes: String, active: Bool, timezone: String, status: LegacyHandoffLedgerStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.title = title
            self.ratio = ratio
            self.notes = notes
            self.active = active
            self.timezone = timezone
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

        func canMoveTo(_ next: LegacyHandoffLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LegacyHandoffLedgerStatus.done || next == LegacyHandoffLedgerStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyHandoffLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy handoff ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> LegacyHandoffLedger {
            return LegacyHandoffLedger(
                code: code,
                label: label,
                specialty: specialty,
                approved: approved,
                diagnosisCode: diagnosisCode,
                title: title,
                ratio: ratio,
                notes: notes,
                active: active,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy handoff ledger in status new.
    static func newLegacyHandoffLedger(_ code: String, label: String) -> LegacyHandoffLedger {
        return LegacyHandoffLedger(
            code: code,
            label: label,
            specialty: "",
            approved: false,
            diagnosisCode: "",
            title: "",
            ratio: 0.0,
            notes: "",
            active: false,
            timezone: "",
            status: LegacyHandoffLedgerStatus.new
        )
    }
}
