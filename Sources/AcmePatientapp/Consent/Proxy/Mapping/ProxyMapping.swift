import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy mapping is in its life cycle.
    enum ProxyMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A proxy mapping. Its code is unique within a tenant.
    final class ProxyMapping {
        var code: String
        var title: String
        var copay: Double
        var allergy: String
        var weight: Double
        var description: String
        var rate: Double
        var summary: String
        var attributes: [String: String]
        var status: ProxyMappingStatus

        init(code: String, title: String, copay: Double, allergy: String, weight: Double, description: String, rate: Double, summary: String, attributes: [String: String], status: ProxyMappingStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.allergy = allergy
            self.weight = weight
            self.description = description
            self.rate = rate
            self.summary = summary
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxyMappingStatus) -> Bool {
            switch status {
            case .planned:
                return next == ProxyMappingStatus.scheduled || next == ProxyMappingStatus.cancelled
            case .scheduled:
                return next == ProxyMappingStatus.inProgress
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ProxyMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("proxy mapping") \(code)"
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

        func adjustedExposure() -> Double {
            return ((rate - weight) * 100).rounded() / 100
        }

        func copyValue() -> ProxyMapping {
            return ProxyMapping(
                code: code,
                title: title,
                copay: copay,
                allergy: allergy,
                weight: weight,
                description: description,
                rate: rate,
                summary: summary,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a proxy mapping in status planned.
    static func newProxyMapping(_ code: String, title: String) -> ProxyMapping {
        return ProxyMapping(
            code: code,
            title: title,
            copay: 0.0,
            allergy: "",
            weight: 0.0,
            description: "",
            rate: 0.0,
            summary: "",
            attributes: [:],
            status: ProxyMappingStatus.planned
        )
    }
}
