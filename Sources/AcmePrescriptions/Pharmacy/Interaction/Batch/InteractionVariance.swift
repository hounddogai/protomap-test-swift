import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction variance is in its life cycle.
    enum InteractionVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a interaction variance and its current status.
    final class InteractionVariance {
        var code: String
        var title: String
        var revision: Int
        var acuity: Int
        var phone: String
        var status: InteractionVarianceStatus

        init(code: String, title: String, revision: Int, acuity: Int, phone: String, status: InteractionVarianceStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.acuity = acuity
            self.phone = phone
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

        func canMoveTo(_ next: InteractionVarianceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == InteractionVarianceStatus.done || next == InteractionVarianceStatus.failed
            case .done:
                return next == InteractionVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("interaction variance") \(code)"
        }

        func netValue() -> Double {
            return ((Double(revision) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionVariance {
            return InteractionVariance(
                code: code,
                title: title,
                revision: revision,
                acuity: acuity,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a interaction variance in status new.
    static func newInteractionVariance(_ code: String, title: String) -> InteractionVariance {
        return InteractionVariance(
            code: code,
            title: title,
            revision: 0,
            acuity: 0,
            phone: "",
            status: InteractionVarianceStatus.new
        )
    }
}
