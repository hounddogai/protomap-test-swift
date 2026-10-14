import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered cleaning claim is in its life cycle.
    enum TieredCleaningClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a tiered cleaning claim and its current status.
    final class TieredCleaningClaim {
        var code: String
        var label: String
        var patientRef: String
        var externalRef: String
        var attempts: Int
        var name: String
        var ratio: Double
        var procedureCode: String
        var status: TieredCleaningClaimStatus

        init(code: String, label: String, patientRef: String, externalRef: String, attempts: Int, name: String, ratio: Double, procedureCode: String, status: TieredCleaningClaimStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.attempts = attempts
            self.name = name
            self.ratio = ratio
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: TieredCleaningClaimStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TieredCleaningClaimStatus.done || next == TieredCleaningClaimStatus.failed
            case .running:
                return next == TieredCleaningClaimStatus.done || next == TieredCleaningClaimStatus.failed
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

        func moveTo(_ next: TieredCleaningClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered cleaning claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered cleaning claim") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(attempts) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> TieredCleaningClaim {
            return TieredCleaningClaim(
                code: code,
                label: label,
                patientRef: patientRef,
                externalRef: externalRef,
                attempts: attempts,
                name: name,
                ratio: ratio,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered cleaning claim in status new.
    static func newTieredCleaningClaim(_ code: String, label: String) -> TieredCleaningClaim {
        return TieredCleaningClaim(
            code: code,
            label: label,
            patientRef: "",
            externalRef: "",
            attempts: 0,
            name: "",
            ratio: 0.0,
            procedureCode: "",
            status: TieredCleaningClaimStatus.new
        )
    }
}
