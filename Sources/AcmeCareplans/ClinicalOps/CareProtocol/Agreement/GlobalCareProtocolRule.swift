import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global care protocol rule is in its life cycle.
    enum GlobalCareProtocolRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One global care protocol rule, with what the planners need to act on it.
    final class GlobalCareProtocolRule {
        var code: String
        var title: String
        var checksum: String
        var attempts: Int
        var patientRef: String
        var createdAt: Int
        var category: String
        var specialty: String
        var updatedAt: Int
        var floorValue: Double
        var expiresAt: Int
        var status: GlobalCareProtocolRuleStatus

        init(code: String, title: String, checksum: String, attempts: Int, patientRef: String, createdAt: Int, category: String, specialty: String, updatedAt: Int, floorValue: Double, expiresAt: Int, status: GlobalCareProtocolRuleStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.attempts = attempts
            self.patientRef = patientRef
            self.createdAt = createdAt
            self.category = category
            self.specialty = specialty
            self.updatedAt = updatedAt
            self.floorValue = floorValue
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

        func canMoveTo(_ next: GlobalCareProtocolRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalCareProtocolRuleStatus.done
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
                return next == GlobalCareProtocolRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCareProtocolRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care protocol rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return ((Double(createdAt) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareProtocolRule {
            return GlobalCareProtocolRule(
                code: code,
                title: title,
                checksum: checksum,
                attempts: attempts,
                patientRef: patientRef,
                createdAt: createdAt,
                category: category,
                specialty: specialty,
                updatedAt: updatedAt,
                floorValue: floorValue,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global care protocol rule in status new.
    static func newGlobalCareProtocolRule(_ code: String, title: String) -> GlobalCareProtocolRule {
        return GlobalCareProtocolRule(
            code: code,
            title: title,
            checksum: "",
            attempts: 0,
            patientRef: "",
            createdAt: 0,
            category: "",
            specialty: "",
            updatedAt: 0,
            floorValue: 0.0,
            expiresAt: 0,
            status: GlobalCareProtocolRuleStatus.new
        )
    }
}
