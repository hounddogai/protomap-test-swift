import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global read estimate is in its life cycle.
    enum GlobalReadEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a global read estimate and its current status.
    final class GlobalReadEstimate {
        var code: String
        var label: String
        var visible: Bool
        var revision: Int
        var discount: Double
        var procedureCode: String
        var visitMinutes: Int
        var amount: Double
        var status: GlobalReadEstimateStatus

        init(code: String, label: String, visible: Bool, revision: Int, discount: Double, procedureCode: String, visitMinutes: Int, amount: Double, status: GlobalReadEstimateStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.revision = revision
            self.discount = discount
            self.procedureCode = procedureCode
            self.visitMinutes = visitMinutes
            self.amount = amount
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

        func canMoveTo(_ next: GlobalReadEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalReadEstimateStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: GlobalReadEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global read estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return (discount * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReadEstimate {
            return GlobalReadEstimate(
                code: code,
                label: label,
                visible: visible,
                revision: revision,
                discount: discount,
                procedureCode: procedureCode,
                visitMinutes: visitMinutes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global read estimate in status new.
    static func newGlobalReadEstimate(_ code: String, label: String) -> GlobalReadEstimate {
        return GlobalReadEstimate(
            code: code,
            label: label,
            visible: false,
            revision: 0,
            discount: 0.0,
            procedureCode: "",
            visitMinutes: 0,
            amount: 0.0,
            status: GlobalReadEstimateStatus.new
        )
    }
}
