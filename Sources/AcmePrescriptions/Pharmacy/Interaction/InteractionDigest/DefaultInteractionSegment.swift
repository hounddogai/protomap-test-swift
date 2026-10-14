import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default interaction segment is in its life cycle.
    enum DefaultInteractionSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default interaction segment. Its code is unique within a tenant.
    final class DefaultInteractionSegment {
        var code: String
        var title: String
        var bed: String
        var discount: Double
        var archived: Bool
        var dosageMg: Double
        var version: Int
        var windowDays: Int
        var source: String
        var status: DefaultInteractionSegmentStatus

        init(code: String, title: String, bed: String, discount: Double, archived: Bool, dosageMg: Double, version: Int, windowDays: Int, source: String, status: DefaultInteractionSegmentStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.discount = discount
            self.archived = archived
            self.dosageMg = dosageMg
            self.version = version
            self.windowDays = windowDays
            self.source = source
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

        func canMoveTo(_ next: DefaultInteractionSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultInteractionSegmentStatus.validated || next == DefaultInteractionSegmentStatus.published
            case .validated:
                return next == DefaultInteractionSegmentStatus.retired
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

        func moveTo(_ next: DefaultInteractionSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default interaction segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (Double(version) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> DefaultInteractionSegment {
            return DefaultInteractionSegment(
                code: code,
                title: title,
                bed: bed,
                discount: discount,
                archived: archived,
                dosageMg: dosageMg,
                version: version,
                windowDays: windowDays,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default interaction segment in status created.
    static func newDefaultInteractionSegment(_ code: String, title: String) -> DefaultInteractionSegment {
        return DefaultInteractionSegment(
            code: code,
            title: title,
            bed: "",
            discount: 0.0,
            archived: false,
            dosageMg: 0.0,
            version: 0,
            windowDays: 0,
            source: "",
            status: DefaultInteractionSegmentStatus.created
        )
    }
}
