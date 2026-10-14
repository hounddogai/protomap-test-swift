import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation claim is in its life cycle.
    enum IsolationClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A isolation claim. Its code is unique within a tenant.
    final class IsolationClaim {
        var code: String
        var label: String
        var ownerID: String
        var checksum: String
        var quantity: Int
        var category: String
        var maximum: Double
        var locale: String
        var visible: Bool
        var country: String
        var status: IsolationClaimStatus

        init(code: String, label: String, ownerID: String, checksum: String, quantity: Int, category: String, maximum: Double, locale: String, visible: Bool, country: String, status: IsolationClaimStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.checksum = checksum
            self.quantity = quantity
            self.category = category
            self.maximum = maximum
            self.locale = locale
            self.visible = visible
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationClaimStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == IsolationClaimStatus.published || next == IsolationClaimStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: IsolationClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return (maximum * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> IsolationClaim {
            return IsolationClaim(
                code: code,
                label: label,
                ownerID: ownerID,
                checksum: checksum,
                quantity: quantity,
                category: category,
                maximum: maximum,
                locale: locale,
                visible: visible,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a isolation claim in status created.
    static func newIsolationClaim(_ code: String, label: String) -> IsolationClaim {
        return IsolationClaim(
            code: code,
            label: label,
            ownerID: "",
            checksum: "",
            quantity: 0,
            category: "",
            maximum: 0.0,
            locale: "",
            visible: false,
            country: "",
            status: IsolationClaimStatus.created
        )
    }
}
