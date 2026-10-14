import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy modality cycle is in its life cycle.
    enum LegacyModalityCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a legacy modality cycle and its current status.
    final class LegacyModalityCycle {
        var code: String
        var name: String
        var patientRef: String
        var country: String
        var attempts: Int
        var margin: Double
        var archived: Bool
        var createdAt: Int
        var status: LegacyModalityCycleStatus

        init(code: String, name: String, patientRef: String, country: String, attempts: Int, margin: Double, archived: Bool, createdAt: Int, status: LegacyModalityCycleStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.country = country
            self.attempts = attempts
            self.margin = margin
            self.archived = archived
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyModalityCycleStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacyModalityCycleStatus.ready
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LegacyModalityCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy modality cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy modality cycle") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(createdAt) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyModalityCycle {
            return LegacyModalityCycle(
                code: code,
                name: name,
                patientRef: patientRef,
                country: country,
                attempts: attempts,
                margin: margin,
                archived: archived,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a legacy modality cycle in status idle.
    static func newLegacyModalityCycle(_ code: String, name: String) -> LegacyModalityCycle {
        return LegacyModalityCycle(
            code: code,
            name: name,
            patientRef: "",
            country: "",
            attempts: 0,
            margin: 0.0,
            archived: false,
            createdAt: 0,
            status: LegacyModalityCycleStatus.idle
        )
    }
}
