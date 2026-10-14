import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol mapping is in its life cycle.
    enum CareProtocolMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care protocol mapping as the care protocol team keeps it.
    final class CareProtocolMapping {
        var code: String
        var title: String
        var active: Bool
        var category: String
        var quantity: Int
        var description: String
        var updatedAt: Int
        var status: CareProtocolMappingStatus

        init(code: String, title: String, active: Bool, category: String, quantity: Int, description: String, updatedAt: Int, status: CareProtocolMappingStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.category = category
            self.quantity = quantity
            self.description = description
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: CareProtocolMappingStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CareProtocolMappingStatus.done
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

        func moveTo(_ next: CareProtocolMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netVolume() -> Double {
            return (Double(updatedAt) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolMapping {
            return CareProtocolMapping(
                code: code,
                title: title,
                active: active,
                category: category,
                quantity: quantity,
                description: description,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a care protocol mapping in status new.
    static func newCareProtocolMapping(_ code: String, title: String) -> CareProtocolMapping {
        return CareProtocolMapping(
            code: code,
            title: title,
            active: false,
            category: "",
            quantity: 0,
            description: "",
            updatedAt: 0,
            status: CareProtocolMappingStatus.new
        )
    }
}
