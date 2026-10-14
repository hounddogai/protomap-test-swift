import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped read preference is in its life cycle.
    enum CappedReadPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped read preference and its current status.
    final class CappedReadPreference {
        var code: String
        var title: String
        var rate: Double
        var clinicianID: String
        var updatedAt: Int
        var limit: Int
        var externalRef: String
        var status: CappedReadPreferenceStatus

        init(code: String, title: String, rate: Double, clinicianID: String, updatedAt: Int, limit: Int, externalRef: String, status: CappedReadPreferenceStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.clinicianID = clinicianID
            self.updatedAt = updatedAt
            self.limit = limit
            self.externalRef = externalRef
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

        func canMoveTo(_ next: CappedReadPreferenceStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedReadPreferenceStatus.queued
            case .queued:
                return next == CappedReadPreferenceStatus.failed
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: CappedReadPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped read preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return (Double(limit) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedReadPreference {
            return CappedReadPreference(
                code: code,
                title: title,
                rate: rate,
                clinicianID: clinicianID,
                updatedAt: updatedAt,
                limit: limit,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped read preference in status new.
    static func newCappedReadPreference(_ code: String, title: String) -> CappedReadPreference {
        return CappedReadPreference(
            code: code,
            title: title,
            rate: 0.0,
            clinicianID: "",
            updatedAt: 0,
            limit: 0,
            externalRef: "",
            status: CappedReadPreferenceStatus.new
        )
    }
}
