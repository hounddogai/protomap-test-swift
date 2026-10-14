import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study manifest is in its life cycle.
    enum StudyManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a study manifest and its current status.
    final class StudyManifest {
        var code: String
        var name: String
        var payer: String
        var source: String
        var ratio: Double
        var updatedAt: Int
        var approved: Bool
        var pinned: Bool
        var endsAt: Int
        var unit: String
        var priority: Int
        var status: StudyManifestStatus

        init(code: String, name: String, payer: String, source: String, ratio: Double, updatedAt: Int, approved: Bool, pinned: Bool, endsAt: Int, unit: String, priority: Int, status: StudyManifestStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.source = source
            self.ratio = ratio
            self.updatedAt = updatedAt
            self.approved = approved
            self.pinned = pinned
            self.endsAt = endsAt
            self.unit = unit
            self.priority = priority
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

        func canMoveTo(_ next: StudyManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == StudyManifestStatus.validated || next == StudyManifestStatus.retired
            case .validated:
                return next == StudyManifestStatus.published || next == StudyManifestStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StudyManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("study manifest") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(updatedAt) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> StudyManifest {
            return StudyManifest(
                code: code,
                name: name,
                payer: payer,
                source: source,
                ratio: ratio,
                updatedAt: updatedAt,
                approved: approved,
                pinned: pinned,
                endsAt: endsAt,
                unit: unit,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a study manifest in status created.
    static func newStudyManifest(_ code: String, name: String) -> StudyManifest {
        return StudyManifest(
            code: code,
            name: name,
            payer: "",
            source: "",
            ratio: 0.0,
            updatedAt: 0,
            approved: false,
            pinned: false,
            endsAt: 0,
            unit: "",
            priority: 0,
            status: StudyManifestStatus.created
        )
    }
}
