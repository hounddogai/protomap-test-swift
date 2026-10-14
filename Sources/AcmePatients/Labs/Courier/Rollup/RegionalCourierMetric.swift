import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional courier metric is in its life cycle.
    enum RegionalCourierMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional courier metric. Its code is unique within a tenant.
    final class RegionalCourierMetric {
        var code: String
        var label: String
        var visible: Bool
        var category: String
        var discount: Double
        var bed: String
        var refills: Int
        var checksum: String
        var segment: String
        var attributes: [String: String]
        var status: RegionalCourierMetricStatus

        init(code: String, label: String, visible: Bool, category: String, discount: Double, bed: String, refills: Int, checksum: String, segment: String, attributes: [String: String], status: RegionalCourierMetricStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.category = category
            self.discount = discount
            self.bed = bed
            self.refills = refills
            self.checksum = checksum
            self.segment = segment
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalCourierMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalCourierMetricStatus.revoked || next == RegionalCourierMetricStatus.expired
            case .granted:
                return next == RegionalCourierMetricStatus.expired
            case .revoked:
                return next == RegionalCourierMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCourierMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional courier metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func projectedVolume() -> Double {
            return ((Double(refills) + discount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCourierMetric {
            return RegionalCourierMetric(
                code: code,
                label: label,
                visible: visible,
                category: category,
                discount: discount,
                bed: bed,
                refills: refills,
                checksum: checksum,
                segment: segment,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional courier metric in status requested.
    static func newRegionalCourierMetric(_ code: String, label: String) -> RegionalCourierMetric {
        return RegionalCourierMetric(
            code: code,
            label: label,
            visible: false,
            category: "",
            discount: 0.0,
            bed: "",
            refills: 0,
            checksum: "",
            segment: "",
            attributes: [:],
            status: RegionalCourierMetricStatus.requested
        )
    }
}
