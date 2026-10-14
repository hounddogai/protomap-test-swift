import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default risk score group is in its life cycle.
    enum DefaultRiskScoreGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One default risk score group, with what the planners need to act on it.
    final class DefaultRiskScoreGroup {
        var code: String
        var label: String
        var country: String
        var category: String
        var startsAt: Int
        var version: Int
        var batchSize: Int
        var refills: Int
        var ratio: Double
        var expiresAt: Int
        var status: DefaultRiskScoreGroupStatus

        init(code: String, label: String, country: String, category: String, startsAt: Int, version: Int, batchSize: Int, refills: Int, ratio: Double, expiresAt: Int, status: DefaultRiskScoreGroupStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.category = category
            self.startsAt = startsAt
            self.version = version
            self.batchSize = batchSize
            self.refills = refills
            self.ratio = ratio
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: DefaultRiskScoreGroupStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultRiskScoreGroupStatus.draining
            case .warming:
                switch next {
                case .ready, .draining:
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

        func moveTo(_ next: DefaultRiskScoreGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default risk score group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("default risk score group") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(refills) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRiskScoreGroup {
            return DefaultRiskScoreGroup(
                code: code,
                label: label,
                country: country,
                category: category,
                startsAt: startsAt,
                version: version,
                batchSize: batchSize,
                refills: refills,
                ratio: ratio,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default risk score group in status idle.
    static func newDefaultRiskScoreGroup(_ code: String, label: String) -> DefaultRiskScoreGroup {
        return DefaultRiskScoreGroup(
            code: code,
            label: label,
            country: "",
            category: "",
            startsAt: 0,
            version: 0,
            batchSize: 0,
            refills: 0,
            ratio: 0.0,
            expiresAt: 0,
            status: DefaultRiskScoreGroupStatus.idle
        )
    }
}
