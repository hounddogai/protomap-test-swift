import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback specimen bundle is in its life cycle.
    enum FallbackSpecimenBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback specimen bundle as the specimen team keeps it.
    final class FallbackSpecimenBundle {
        var code: String
        var label: String
        var revision: Int
        var floorValue: Double
        var unit: String
        var status: FallbackSpecimenBundleStatus

        init(code: String, label: String, revision: Int, floorValue: Double, unit: String, status: FallbackSpecimenBundleStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.floorValue = floorValue
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

        func canMoveTo(_ next: FallbackSpecimenBundleStatus) -> Bool {
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
                return next == FallbackSpecimenBundleStatus.ready || next == FallbackSpecimenBundleStatus.stopped
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

        func moveTo(_ next: FallbackSpecimenBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback specimen bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("fallback specimen bundle") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(revision) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FallbackSpecimenBundle {
            return FallbackSpecimenBundle(
                code: code,
                label: label,
                revision: revision,
                floorValue: floorValue,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback specimen bundle in status idle.
    static func newFallbackSpecimenBundle(_ code: String, label: String) -> FallbackSpecimenBundle {
        return FallbackSpecimenBundle(
            code: code,
            label: label,
            revision: 0,
            floorValue: 0.0,
            unit: "",
            status: FallbackSpecimenBundleStatus.idle
        )
    }
}
