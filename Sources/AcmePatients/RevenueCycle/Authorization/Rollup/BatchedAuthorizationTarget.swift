import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched authorization target is in its life cycle.
    enum BatchedAuthorizationTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched authorization target. Its code is unique within a tenant.
    final class BatchedAuthorizationTarget {
        var code: String
        var name: String
        var createdAt: Int
        var refills: Int
        var unit: String
        var patientRef: String
        var windowDays: Int
        var region: String
        var dosageMg: Double
        var visible: Bool
        var status: BatchedAuthorizationTargetStatus

        init(code: String, name: String, createdAt: Int, refills: Int, unit: String, patientRef: String, windowDays: Int, region: String, dosageMg: Double, visible: Bool, status: BatchedAuthorizationTargetStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.refills = refills
            self.unit = unit
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.region = region
            self.dosageMg = dosageMg
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedAuthorizationTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == BatchedAuthorizationTargetStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: BatchedAuthorizationTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched authorization target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((Double(windowDays) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedAuthorizationTarget {
            return BatchedAuthorizationTarget(
                code: code,
                name: name,
                createdAt: createdAt,
                refills: refills,
                unit: unit,
                patientRef: patientRef,
                windowDays: windowDays,
                region: region,
                dosageMg: dosageMg,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a batched authorization target in status planned.
    static func newBatchedAuthorizationTarget(_ code: String, name: String) -> BatchedAuthorizationTarget {
        return BatchedAuthorizationTarget(
            code: code,
            name: name,
            createdAt: 0,
            refills: 0,
            unit: "",
            patientRef: "",
            windowDays: 0,
            region: "",
            dosageMg: 0.0,
            visible: false,
            status: BatchedAuthorizationTargetStatus.planned
        )
    }
}
