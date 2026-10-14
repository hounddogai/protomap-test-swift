import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form snapshot is in its life cycle.
    enum ConsentFormSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A consent form snapshot as the consent form team keeps it.
    final class ConsentFormSnapshot {
        var code: String
        var label: String
        var createdAt: Int
        var weight: Double
        var category: String
        var tags: [String]
        var margin: Double
        var threshold: Double
        var region: String
        var status: ConsentFormSnapshotStatus

        init(code: String, label: String, createdAt: Int, weight: Double, category: String, tags: [String], margin: Double, threshold: Double, region: String, status: ConsentFormSnapshotStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.weight = weight
            self.category = category
            self.tags = tags
            self.margin = margin
            self.threshold = threshold
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormSnapshotStatus) -> Bool {
            switch status {
            case .created:
                return next == ConsentFormSnapshotStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ConsentFormSnapshotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return ((threshold + weight) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormSnapshot {
            return ConsentFormSnapshot(
                code: code,
                label: label,
                createdAt: createdAt,
                weight: weight,
                category: category,
                tags: tags,
                margin: margin,
                threshold: threshold,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a consent form snapshot in status created.
    static func newConsentFormSnapshot(_ code: String, label: String) -> ConsentFormSnapshot {
        return ConsentFormSnapshot(
            code: code,
            label: label,
            createdAt: 0,
            weight: 0.0,
            category: "",
            tags: [],
            margin: 0.0,
            threshold: 0.0,
            region: "",
            status: ConsentFormSnapshotStatus.created
        )
    }
}
