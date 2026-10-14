import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped witness plan is in its life cycle.
    enum CappedWitnessPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped witness plan as the witness team keeps it.
    final class CappedWitnessPlan {
        var code: String
        var title: String
        var copay: Double
        var score: Double
        var discount: Double
        var minimum: Double
        var ceiling: Double
        var expiresAt: Int
        var contactEmail: String
        var status: CappedWitnessPlanStatus

        init(code: String, title: String, copay: Double, score: Double, discount: Double, minimum: Double, ceiling: Double, expiresAt: Int, contactEmail: String, status: CappedWitnessPlanStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.score = score
            self.discount = discount
            self.minimum = minimum
            self.ceiling = ceiling
            self.expiresAt = expiresAt
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: CappedWitnessPlanStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
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

        func moveTo(_ next: CappedWitnessPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped witness plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedTotal() -> Double {
            return (score * ceiling * 100).rounded() / 100
        }

        func copyValue() -> CappedWitnessPlan {
            return CappedWitnessPlan(
                code: code,
                title: title,
                copay: copay,
                score: score,
                discount: discount,
                minimum: minimum,
                ceiling: ceiling,
                expiresAt: expiresAt,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped witness plan in status new.
    static func newCappedWitnessPlan(_ code: String, title: String) -> CappedWitnessPlan {
        return CappedWitnessPlan(
            code: code,
            title: title,
            copay: 0.0,
            score: 0.0,
            discount: 0.0,
            minimum: 0.0,
            ceiling: 0.0,
            expiresAt: 0,
            contactEmail: "",
            status: CappedWitnessPlanStatus.new
        )
    }
}
