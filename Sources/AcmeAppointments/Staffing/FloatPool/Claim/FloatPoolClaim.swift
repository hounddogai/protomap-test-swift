import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool claim is in its life cycle.
    enum FloatPoolClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A float pool claim. Its code is unique within a tenant.
    final class FloatPoolClaim {
        var code: String
        var label: String
        var createdAt: Int
        var approved: Bool
        var country: String
        var active: Bool
        var minimum: Double
        var status: FloatPoolClaimStatus

        init(code: String, label: String, createdAt: Int, approved: Bool, country: String, active: Bool, minimum: Double, status: FloatPoolClaimStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.approved = approved
            self.country = country
            self.active = active
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

        func canMoveTo(_ next: FloatPoolClaimStatus) -> Bool {
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
                return next == FloatPoolClaimStatus.done || next == FloatPoolClaimStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == FloatPoolClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("float pool claim") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(createdAt) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolClaim {
            return FloatPoolClaim(
                code: code,
                label: label,
                createdAt: createdAt,
                approved: approved,
                country: country,
                active: active,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a float pool claim in status new.
    static func newFloatPoolClaim(_ code: String, label: String) -> FloatPoolClaim {
        return FloatPoolClaim(
            code: code,
            label: label,
            createdAt: 0,
            approved: false,
            country: "",
            active: false,
            minimum: 0.0,
            status: FloatPoolClaimStatus.new
        )
    }
}
