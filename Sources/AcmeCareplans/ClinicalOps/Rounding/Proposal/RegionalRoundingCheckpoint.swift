import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional rounding checkpoint is in its life cycle.
    enum RegionalRoundingCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a regional rounding checkpoint and its current status.
    final class RegionalRoundingCheckpoint {
        var code: String
        var label: String
        var externalRef: String
        var region: String
        var ratio: Double
        var phone: String
        var patientRef: String
        var windowDays: Int
        var approved: Bool
        var status: RegionalRoundingCheckpointStatus

        init(code: String, label: String, externalRef: String, region: String, ratio: Double, phone: String, patientRef: String, windowDays: Int, approved: Bool, status: RegionalRoundingCheckpointStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.region = region
            self.ratio = ratio
            self.phone = phone
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.approved = approved
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

        func canMoveTo(_ next: RegionalRoundingCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RegionalRoundingCheckpointStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RegionalRoundingCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalRoundingCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional rounding checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netVolume() -> Double {
            return (Double(windowDays) * ratio * 100).rounded() / 100
        }

        func copyValue() -> RegionalRoundingCheckpoint {
            return RegionalRoundingCheckpoint(
                code: code,
                label: label,
                externalRef: externalRef,
                region: region,
                ratio: ratio,
                phone: phone,
                patientRef: patientRef,
                windowDays: windowDays,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional rounding checkpoint in status idle.
    static func newRegionalRoundingCheckpoint(_ code: String, label: String) -> RegionalRoundingCheckpoint {
        return RegionalRoundingCheckpoint(
            code: code,
            label: label,
            externalRef: "",
            region: "",
            ratio: 0.0,
            phone: "",
            patientRef: "",
            windowDays: 0,
            approved: false,
            status: RegionalRoundingCheckpointStatus.idle
        )
    }
}
