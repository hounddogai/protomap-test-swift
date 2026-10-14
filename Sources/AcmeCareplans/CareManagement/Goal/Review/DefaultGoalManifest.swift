import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default goal manifest is in its life cycle.
    enum DefaultGoalManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One default goal manifest, with what the planners need to act on it.
    final class DefaultGoalManifest {
        var code: String
        var label: String
        var discount: Double
        var rate: Double
        var endsAt: Int
        var country: String
        var specialty: String
        var visitMinutes: Int
        var name: String
        var checksum: String
        var status: DefaultGoalManifestStatus

        init(code: String, label: String, discount: Double, rate: Double, endsAt: Int, country: String, specialty: String, visitMinutes: Int, name: String, checksum: String, status: DefaultGoalManifestStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.rate = rate
            self.endsAt = endsAt
            self.country = country
            self.specialty = specialty
            self.visitMinutes = visitMinutes
            self.name = name
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultGoalManifestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultGoalManifestStatus.inReview
            case .inReview:
                return next == DefaultGoalManifestStatus.reopened || next == DefaultGoalManifestStatus.archived
            case .resolved:
                return next == DefaultGoalManifestStatus.reopened || next == DefaultGoalManifestStatus.archived
            case .reopened:
                return next == DefaultGoalManifestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultGoalManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default goal manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return ((Double(visitMinutes) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultGoalManifest {
            return DefaultGoalManifest(
                code: code,
                label: label,
                discount: discount,
                rate: rate,
                endsAt: endsAt,
                country: country,
                specialty: specialty,
                visitMinutes: visitMinutes,
                name: name,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default goal manifest in status open.
    static func newDefaultGoalManifest(_ code: String, label: String) -> DefaultGoalManifest {
        return DefaultGoalManifest(
            code: code,
            label: label,
            discount: 0.0,
            rate: 0.0,
            endsAt: 0,
            country: "",
            specialty: "",
            visitMinutes: 0,
            name: "",
            checksum: "",
            status: DefaultGoalManifestStatus.`open`
        )
    }
}
