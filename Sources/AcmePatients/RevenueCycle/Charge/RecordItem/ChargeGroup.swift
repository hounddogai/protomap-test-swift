import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge group is in its life cycle.
    enum ChargeGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a charge group and its current status.
    final class ChargeGroup {
        var code: String
        var name: String
        var source: String
        var patientRef: String
        var allergy: String
        var ratio: Double
        var windowDays: Int
        var region: String
        var label: String
        var status: ChargeGroupStatus

        init(code: String, name: String, source: String, patientRef: String, allergy: String, ratio: Double, windowDays: Int, region: String, label: String, status: ChargeGroupStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.patientRef = patientRef
            self.allergy = allergy
            self.ratio = ratio
            self.windowDays = windowDays
            self.region = region
            self.label = label
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

        func canMoveTo(_ next: ChargeGroupStatus) -> Bool {
            switch status {
            case .idle:
                return next == ChargeGroupStatus.warming || next == ChargeGroupStatus.ready
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
                return next == ChargeGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("charge group") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((ratio - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeGroup {
            return ChargeGroup(
                code: code,
                name: name,
                source: source,
                patientRef: patientRef,
                allergy: allergy,
                ratio: ratio,
                windowDays: windowDays,
                region: region,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a charge group in status idle.
    static func newChargeGroup(_ code: String, name: String) -> ChargeGroup {
        return ChargeGroup(
            code: code,
            name: name,
            source: "",
            patientRef: "",
            allergy: "",
            ratio: 0.0,
            windowDays: 0,
            region: "",
            label: "",
            status: ChargeGroupStatus.idle
        )
    }
}
