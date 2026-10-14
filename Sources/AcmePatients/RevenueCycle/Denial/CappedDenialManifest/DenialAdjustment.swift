import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial adjustment is in its life cycle.
    enum DenialAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A denial adjustment as the denial team keeps it.
    final class DenialAdjustment {
        var code: String
        var name: String
        var updatedAt: Int
        var category: String
        var limit: Int
        var retries: Int
        var attributes: [String: String]
        var status: DenialAdjustmentStatus

        init(code: String, name: String, updatedAt: Int, category: String, limit: Int, retries: Int, attributes: [String: String], status: DenialAdjustmentStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.category = category
            self.limit = limit
            self.retries = retries
            self.attributes = attributes
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

        func canMoveTo(_ next: DenialAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                return next == DenialAdjustmentStatus.queued
            case .queued:
                switch next {
                case .running, .done:
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

        func moveTo(_ next: DenialAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
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

        func effectiveValue() -> Double {
            return ((Double(limit) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> DenialAdjustment {
            return DenialAdjustment(
                code: code,
                name: name,
                updatedAt: updatedAt,
                category: category,
                limit: limit,
                retries: retries,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a denial adjustment in status new.
    static func newDenialAdjustment(_ code: String, name: String) -> DenialAdjustment {
        return DenialAdjustment(
            code: code,
            name: name,
            updatedAt: 0,
            category: "",
            limit: 0,
            retries: 0,
            attributes: [:],
            status: DenialAdjustmentStatus.new
        )
    }
}
