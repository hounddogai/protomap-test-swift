import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction plan is in its life cycle.
    enum InteractionPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A interaction plan as the interaction team keeps it.
    final class InteractionPlan {
        var code: String
        var name: String
        var description: String
        var threshold: Double
        var checksum: String
        var ward: String
        var category: String
        var expiresAt: Int
        var status: InteractionPlanStatus

        init(code: String, name: String, description: String, threshold: Double, checksum: String, ward: String, category: String, expiresAt: Int, status: InteractionPlanStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.threshold = threshold
            self.checksum = checksum
            self.ward = ward
            self.category = category
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: InteractionPlanStatus) -> Bool {
            switch status {
            case .new:
                return next == InteractionPlanStatus.failed
            case .queued:
                return next == InteractionPlanStatus.done || next == InteractionPlanStatus.failed
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

        func moveTo(_ next: InteractionPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(expiresAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> InteractionPlan {
            return InteractionPlan(
                code: code,
                name: name,
                description: description,
                threshold: threshold,
                checksum: checksum,
                ward: ward,
                category: category,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a interaction plan in status new.
    static func newInteractionPlan(_ code: String, name: String) -> InteractionPlan {
        return InteractionPlan(
            code: code,
            name: name,
            description: "",
            threshold: 0.0,
            checksum: "",
            ward: "",
            category: "",
            expiresAt: 0,
            status: InteractionPlanStatus.new
        )
    }
}
