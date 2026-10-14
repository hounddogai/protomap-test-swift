import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted language tier is in its life cycle.
    enum WeightedLanguageTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a weighted language tier and its current status.
    final class WeightedLanguageTier {
        var code: String
        var title: String
        var notes: String
        var patientRef: String
        var expiresAt: Int
        var startsAt: Int
        var minimum: Double
        var status: WeightedLanguageTierStatus

        init(code: String, title: String, notes: String, patientRef: String, expiresAt: Int, startsAt: Int, minimum: Double, status: WeightedLanguageTierStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.startsAt = startsAt
            self.minimum = minimum
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

        func canMoveTo(_ next: WeightedLanguageTierStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedLanguageTierStatus.running || next == WeightedLanguageTierStatus.done
            case .queued:
                return next == WeightedLanguageTierStatus.running || next == WeightedLanguageTierStatus.failed
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

        func moveTo(_ next: WeightedLanguageTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted language tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> WeightedLanguageTier {
            return WeightedLanguageTier(
                code: code,
                title: title,
                notes: notes,
                patientRef: patientRef,
                expiresAt: expiresAt,
                startsAt: startsAt,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted language tier in status new.
    static func newWeightedLanguageTier(_ code: String, title: String) -> WeightedLanguageTier {
        return WeightedLanguageTier(
            code: code,
            title: title,
            notes: "",
            patientRef: "",
            expiresAt: 0,
            startsAt: 0,
            minimum: 0.0,
            status: WeightedLanguageTierStatus.new
        )
    }
}
