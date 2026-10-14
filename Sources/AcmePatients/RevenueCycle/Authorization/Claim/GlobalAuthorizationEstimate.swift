import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global authorization estimate is in its life cycle.
    enum GlobalAuthorizationEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One global authorization estimate, with what the planners need to act on it.
    final class GlobalAuthorizationEstimate {
        var code: String
        var name: String
        var windowDays: Int
        var attributes: [String: String]
        var region: String
        var category: String
        var minimum: Double
        var revision: Int
        var batchSize: Int
        var status: GlobalAuthorizationEstimateStatus

        init(code: String, name: String, windowDays: Int, attributes: [String: String], region: String, category: String, minimum: Double, revision: Int, batchSize: Int, status: GlobalAuthorizationEstimateStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.attributes = attributes
            self.region = region
            self.category = category
            self.minimum = minimum
            self.revision = revision
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalAuthorizationEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == GlobalAuthorizationEstimateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalAuthorizationEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global authorization estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func netVolume() -> Double {
            return ((Double(revision) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalAuthorizationEstimate {
            return GlobalAuthorizationEstimate(
                code: code,
                name: name,
                windowDays: windowDays,
                attributes: attributes,
                region: region,
                category: category,
                minimum: minimum,
                revision: revision,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global authorization estimate in status proposed.
    static func newGlobalAuthorizationEstimate(_ code: String, name: String) -> GlobalAuthorizationEstimate {
        return GlobalAuthorizationEstimate(
            code: code,
            name: name,
            windowDays: 0,
            attributes: [:],
            region: "",
            category: "",
            minimum: 0.0,
            revision: 0,
            batchSize: 0,
            status: GlobalAuthorizationEstimateStatus.proposed
        )
    }
}
