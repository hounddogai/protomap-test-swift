import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness review is in its life cycle.
    enum WitnessReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A witness review as the witness team keeps it.
    final class WitnessReview {
        var code: String
        var name: String
        var limit: Int
        var checksum: String
        var createdAt: Int
        var startsAt: Int
        var approved: Bool
        var dosageMg: Double
        var attributes: [String: String]
        var status: WitnessReviewStatus

        init(code: String, name: String, limit: Int, checksum: String, createdAt: Int, startsAt: Int, approved: Bool, dosageMg: Double, attributes: [String: String], status: WitnessReviewStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.checksum = checksum
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.approved = approved
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: WitnessReviewStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == WitnessReviewStatus.done || next == WitnessReviewStatus.failed
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

        func moveTo(_ next: WitnessReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
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
            return (Double(startsAt) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> WitnessReview {
            return WitnessReview(
                code: code,
                name: name,
                limit: limit,
                checksum: checksum,
                createdAt: createdAt,
                startsAt: startsAt,
                approved: approved,
                dosageMg: dosageMg,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a witness review in status new.
    static func newWitnessReview(_ code: String, name: String) -> WitnessReview {
        return WitnessReview(
            code: code,
            name: name,
            limit: 0,
            checksum: "",
            createdAt: 0,
            startsAt: 0,
            approved: false,
            dosageMg: 0.0,
            attributes: [:],
            status: WitnessReviewStatus.new
        )
    }
}
