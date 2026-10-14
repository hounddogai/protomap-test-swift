import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched dispense bundle is in its life cycle.
    enum BatchedDispenseBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched dispense bundle as the dispense team keeps it.
    final class BatchedDispenseBundle {
        var code: String
        var label: String
        var facility: String
        var region: String
        var timezone: String
        var retries: Int
        var score: Double
        var createdAt: Int
        var active: Bool
        var patientRef: String
        var windowDays: Int
        var status: BatchedDispenseBundleStatus

        init(code: String, label: String, facility: String, region: String, timezone: String, retries: Int, score: Double, createdAt: Int, active: Bool, patientRef: String, windowDays: Int, status: BatchedDispenseBundleStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.region = region
            self.timezone = timezone
            self.retries = retries
            self.score = score
            self.createdAt = createdAt
            self.active = active
            self.patientRef = patientRef
            self.windowDays = windowDays
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

        func canMoveTo(_ next: BatchedDispenseBundleStatus) -> Bool {
            switch status {
            case .new:
                return next == BatchedDispenseBundleStatus.running || next == BatchedDispenseBundleStatus.done
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == BatchedDispenseBundleStatus.done || next == BatchedDispenseBundleStatus.failed
            case .done:
                return next == BatchedDispenseBundleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedDispenseBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched dispense bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return (score * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDispenseBundle {
            return BatchedDispenseBundle(
                code: code,
                label: label,
                facility: facility,
                region: region,
                timezone: timezone,
                retries: retries,
                score: score,
                createdAt: createdAt,
                active: active,
                patientRef: patientRef,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched dispense bundle in status new.
    static func newBatchedDispenseBundle(_ code: String, label: String) -> BatchedDispenseBundle {
        return BatchedDispenseBundle(
            code: code,
            label: label,
            facility: "",
            region: "",
            timezone: "",
            retries: 0,
            score: 0.0,
            createdAt: 0,
            active: false,
            patientRef: "",
            windowDays: 0,
            status: BatchedDispenseBundleStatus.new
        )
    }
}
