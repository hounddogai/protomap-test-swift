import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set estimate is in its life cycle.
    enum OrderSetEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A order set estimate. Its code is unique within a tenant.
    final class OrderSetEstimate {
        var code: String
        var name: String
        var revision: Int
        var category: String
        var sequence: Int
        var updatedAt: Int
        var attributes: [String: String]
        var contactEmail: String
        var procedureCode: String
        var windowDays: Int
        var status: OrderSetEstimateStatus

        init(code: String, name: String, revision: Int, category: String, sequence: Int, updatedAt: Int, attributes: [String: String], contactEmail: String, procedureCode: String, windowDays: Int, status: OrderSetEstimateStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.category = category
            self.sequence = sequence
            self.updatedAt = updatedAt
            self.attributes = attributes
            self.contactEmail = contactEmail
            self.procedureCode = procedureCode
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: OrderSetEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("order set estimate") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedExposure() -> Double {
            return ((Double(windowDays) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetEstimate {
            return OrderSetEstimate(
                code: code,
                name: name,
                revision: revision,
                category: category,
                sequence: sequence,
                updatedAt: updatedAt,
                attributes: attributes,
                contactEmail: contactEmail,
                procedureCode: procedureCode,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a order set estimate in status requested.
    static func newOrderSetEstimate(_ code: String, name: String) -> OrderSetEstimate {
        return OrderSetEstimate(
            code: code,
            name: name,
            revision: 0,
            category: "",
            sequence: 0,
            updatedAt: 0,
            attributes: [:],
            contactEmail: "",
            procedureCode: "",
            windowDays: 0,
            status: OrderSetEstimateStatus.requested
        )
    }
}
