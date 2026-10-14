import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback eligibility metric is in its life cycle.
    enum FallbackEligibilityMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback eligibility metric as the eligibility team keeps it.
    final class FallbackEligibilityMetric {
        var code: String
        var name: String
        var batchSize: Int
        var floorValue: Double
        var ward: String
        var currency: String
        var bed: String
        var pinned: Bool
        var notes: String
        var visible: Bool
        var tags: [String]
        var status: FallbackEligibilityMetricStatus

        init(code: String, name: String, batchSize: Int, floorValue: Double, ward: String, currency: String, bed: String, pinned: Bool, notes: String, visible: Bool, tags: [String], status: FallbackEligibilityMetricStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.floorValue = floorValue
            self.ward = ward
            self.currency = currency
            self.bed = bed
            self.pinned = pinned
            self.notes = notes
            self.visible = visible
            self.tags = tags
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

        func canMoveTo(_ next: FallbackEligibilityMetricStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackEligibilityMetricStatus.queued
            case .queued:
                return next == FallbackEligibilityMetricStatus.running || next == FallbackEligibilityMetricStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FallbackEligibilityMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback eligibility metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((floorValue - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackEligibilityMetric {
            return FallbackEligibilityMetric(
                code: code,
                name: name,
                batchSize: batchSize,
                floorValue: floorValue,
                ward: ward,
                currency: currency,
                bed: bed,
                pinned: pinned,
                notes: notes,
                visible: visible,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback eligibility metric in status new.
    static func newFallbackEligibilityMetric(_ code: String, name: String) -> FallbackEligibilityMetric {
        return FallbackEligibilityMetric(
            code: code,
            name: name,
            batchSize: 0,
            floorValue: 0.0,
            ward: "",
            currency: "",
            bed: "",
            pinned: false,
            notes: "",
            visible: false,
            tags: [],
            status: FallbackEligibilityMetricStatus.new
        )
    }
}
