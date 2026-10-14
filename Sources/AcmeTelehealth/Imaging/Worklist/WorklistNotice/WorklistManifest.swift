import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist manifest is in its life cycle.
    enum WorklistManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A worklist manifest. Its code is unique within a tenant.
    final class WorklistManifest {
        var code: String
        var title: String
        var endsAt: Int
        var batchSize: Int
        var unit: String
        var status: WorklistManifestStatus

        init(code: String, title: String, endsAt: Int, batchSize: Int, unit: String, status: WorklistManifestStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.batchSize = batchSize
            self.unit = unit
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

        func canMoveTo(_ next: WorklistManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == WorklistManifestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("worklist manifest") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(batchSize) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistManifest {
            return WorklistManifest(
                code: code,
                title: title,
                endsAt: endsAt,
                batchSize: batchSize,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a worklist manifest in status idle.
    static func newWorklistManifest(_ code: String, title: String) -> WorklistManifest {
        return WorklistManifest(
            code: code,
            title: title,
            endsAt: 0,
            batchSize: 0,
            unit: "",
            status: WorklistManifestStatus.idle
        )
    }
}
