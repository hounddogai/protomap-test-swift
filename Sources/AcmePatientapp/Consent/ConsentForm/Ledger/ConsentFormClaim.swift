import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form claim is in its life cycle.
    enum ConsentFormClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A consent form claim as the consent form team keeps it.
    final class ConsentFormClaim {
        var code: String
        var label: String
        var visitMinutes: Int
        var category: String
        var updatedAt: Int
        var version: Int
        var externalRef: String
        var windowDays: Int
        var quantity: Int
        var budget: Double
        var status: ConsentFormClaimStatus

        init(code: String, label: String, visitMinutes: Int, category: String, updatedAt: Int, version: Int, externalRef: String, windowDays: Int, quantity: Int, budget: Double, status: ConsentFormClaimStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.category = category
            self.updatedAt = updatedAt
            self.version = version
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.quantity = quantity
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormClaimStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ConsentFormClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedVolume() -> Double {
            return ((Double(visitMinutes) - budget) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormClaim {
            return ConsentFormClaim(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                category: category,
                updatedAt: updatedAt,
                version: version,
                externalRef: externalRef,
                windowDays: windowDays,
                quantity: quantity,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a consent form claim in status draft.
    static func newConsentFormClaim(_ code: String, label: String) -> ConsentFormClaim {
        return ConsentFormClaim(
            code: code,
            label: label,
            visitMinutes: 0,
            category: "",
            updatedAt: 0,
            version: 0,
            externalRef: "",
            windowDays: 0,
            quantity: 0,
            budget: 0.0,
            status: ConsentFormClaimStatus.draft
        )
    }
}
