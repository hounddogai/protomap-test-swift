import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network rule is in its life cycle.
    enum NetworkRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One network rule, with what the planners need to act on it.
    final class NetworkRule {
        var code: String
        var title: String
        var floorValue: Double
        var country: String
        var windowDays: Int
        var patientRef: String
        var checksum: String
        var weight: Double
        var refills: Int
        var segment: String
        var status: NetworkRuleStatus

        init(code: String, title: String, floorValue: Double, country: String, windowDays: Int, patientRef: String, checksum: String, weight: Double, refills: Int, segment: String, status: NetworkRuleStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.country = country
            self.windowDays = windowDays
            self.patientRef = patientRef
            self.checksum = checksum
            self.weight = weight
            self.refills = refills
            self.segment = segment
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

        func canMoveTo(_ next: NetworkRuleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == NetworkRuleStatus.ready || next == NetworkRuleStatus.stopped
            case .ready:
                return next == NetworkRuleStatus.draining || next == NetworkRuleStatus.stopped
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

        func moveTo(_ next: NetworkRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedVolume() -> Double {
            return (floorValue * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> NetworkRule {
            return NetworkRule(
                code: code,
                title: title,
                floorValue: floorValue,
                country: country,
                windowDays: windowDays,
                patientRef: patientRef,
                checksum: checksum,
                weight: weight,
                refills: refills,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a network rule in status idle.
    static func newNetworkRule(_ code: String, title: String) -> NetworkRule {
        return NetworkRule(
            code: code,
            title: title,
            floorValue: 0.0,
            country: "",
            windowDays: 0,
            patientRef: "",
            checksum: "",
            weight: 0.0,
            refills: 0,
            segment: "",
            status: NetworkRuleStatus.idle
        )
    }
}
