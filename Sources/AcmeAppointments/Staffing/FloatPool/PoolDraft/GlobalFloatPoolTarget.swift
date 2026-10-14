import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global float pool target is in its life cycle.
    enum GlobalFloatPoolTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One global float pool target, with what the planners need to act on it.
    final class GlobalFloatPoolTarget {
        var code: String
        var name: String
        var attributes: [String: String]
        var diagnosisCode: String
        var refills: Int
        var rate: Double
        var graceDays: Int
        var bed: String
        var startsAt: Int
        var channel: String
        var reviewer: String
        var status: GlobalFloatPoolTargetStatus

        init(code: String, name: String, attributes: [String: String], diagnosisCode: String, refills: Int, rate: Double, graceDays: Int, bed: String, startsAt: Int, channel: String, reviewer: String, status: GlobalFloatPoolTargetStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.diagnosisCode = diagnosisCode
            self.refills = refills
            self.rate = rate
            self.graceDays = graceDays
            self.bed = bed
            self.startsAt = startsAt
            self.channel = channel
            self.reviewer = reviewer
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

        func canMoveTo(_ next: GlobalFloatPoolTargetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalFloatPoolTargetStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: GlobalFloatPoolTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global float pool target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global float pool target") \(code)"
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

        func adjustedValue() -> Double {
            return ((rate + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFloatPoolTarget {
            return GlobalFloatPoolTarget(
                code: code,
                name: name,
                attributes: attributes,
                diagnosisCode: diagnosisCode,
                refills: refills,
                rate: rate,
                graceDays: graceDays,
                bed: bed,
                startsAt: startsAt,
                channel: channel,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global float pool target in status proposed.
    static func newGlobalFloatPoolTarget(_ code: String, name: String) -> GlobalFloatPoolTarget {
        return GlobalFloatPoolTarget(
            code: code,
            name: name,
            attributes: [:],
            diagnosisCode: "",
            refills: 0,
            rate: 0.0,
            graceDays: 0,
            bed: "",
            startsAt: 0,
            channel: "",
            reviewer: "",
            status: GlobalFloatPoolTargetStatus.proposed
        )
    }
}
