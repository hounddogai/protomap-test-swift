import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered accession profile is in its life cycle.
    enum TieredAccessionProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a tiered accession profile and its current status.
    final class TieredAccessionProfile {
        var code: String
        var label: String
        var procedureCode: String
        var name: String
        var refills: Int
        var minimum: Double
        var status: TieredAccessionProfileStatus

        init(code: String, label: String, procedureCode: String, name: String, refills: Int, minimum: Double, status: TieredAccessionProfileStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.name = name
            self.refills = refills
            self.minimum = minimum
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

        func canMoveTo(_ next: TieredAccessionProfileStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TieredAccessionProfileStatus.running || next == TieredAccessionProfileStatus.failed
            case .running:
                return next == TieredAccessionProfileStatus.done || next == TieredAccessionProfileStatus.failed
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

        func moveTo(_ next: TieredAccessionProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered accession profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered accession profile") \(code)"
        }

        func weightedValue() -> Double {
            return ((minimum - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> TieredAccessionProfile {
            return TieredAccessionProfile(
                code: code,
                label: label,
                procedureCode: procedureCode,
                name: name,
                refills: refills,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered accession profile in status new.
    static func newTieredAccessionProfile(_ code: String, label: String) -> TieredAccessionProfile {
        return TieredAccessionProfile(
            code: code,
            label: label,
            procedureCode: "",
            name: "",
            refills: 0,
            minimum: 0.0,
            status: TieredAccessionProfileStatus.new
        )
    }
}
