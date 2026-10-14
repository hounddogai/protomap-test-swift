import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted credential entry is in its life cycle.
    enum WeightedCredentialEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted credential entry as the credential team keeps it.
    final class WeightedCredentialEntry {
        var code: String
        var name: String
        var approved: Bool
        var ownerID: String
        var sequence: Int
        var refills: Int
        var rate: Double
        var limit: Int
        var windowDays: Int
        var description: String
        var status: WeightedCredentialEntryStatus

        init(code: String, name: String, approved: Bool, ownerID: String, sequence: Int, refills: Int, rate: Double, limit: Int, windowDays: Int, description: String, status: WeightedCredentialEntryStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.ownerID = ownerID
            self.sequence = sequence
            self.refills = refills
            self.rate = rate
            self.limit = limit
            self.windowDays = windowDays
            self.description = description
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

        func canMoveTo(_ next: WeightedCredentialEntryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == WeightedCredentialEntryStatus.failed
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

        func moveTo(_ next: WeightedCredentialEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted credential entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((Double(windowDays) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCredentialEntry {
            return WeightedCredentialEntry(
                code: code,
                name: name,
                approved: approved,
                ownerID: ownerID,
                sequence: sequence,
                refills: refills,
                rate: rate,
                limit: limit,
                windowDays: windowDays,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted credential entry in status new.
    static func newWeightedCredentialEntry(_ code: String, name: String) -> WeightedCredentialEntry {
        return WeightedCredentialEntry(
            code: code,
            name: name,
            approved: false,
            ownerID: "",
            sequence: 0,
            refills: 0,
            rate: 0.0,
            limit: 0,
            windowDays: 0,
            description: "",
            status: WeightedCredentialEntryStatus.new
        )
    }
}
