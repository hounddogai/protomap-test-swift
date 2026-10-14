import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal read exception is in its life cycle.
    enum SeasonalReadExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal read exception as the read team keeps it.
    final class SeasonalReadException {
        var code: String
        var label: String
        var minimum: Double
        var retries: Int
        var revision: Int
        var ceiling: Double
        var notes: String
        var bed: String
        var country: String
        var margin: Double
        var copay: Double
        var status: SeasonalReadExceptionStatus

        init(code: String, label: String, minimum: Double, retries: Int, revision: Int, ceiling: Double, notes: String, bed: String, country: String, margin: Double, copay: Double, status: SeasonalReadExceptionStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.retries = retries
            self.revision = revision
            self.ceiling = ceiling
            self.notes = notes
            self.bed = bed
            self.country = country
            self.margin = margin
            self.copay = copay
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

        func canMoveTo(_ next: SeasonalReadExceptionStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalReadExceptionStatus.validated
            case .validated:
                return next == SeasonalReadExceptionStatus.published || next == SeasonalReadExceptionStatus.retired
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

        func moveTo(_ next: SeasonalReadExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal read exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("seasonal read exception") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((copay - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalReadException {
            return SeasonalReadException(
                code: code,
                label: label,
                minimum: minimum,
                retries: retries,
                revision: revision,
                ceiling: ceiling,
                notes: notes,
                bed: bed,
                country: country,
                margin: margin,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a seasonal read exception in status created.
    static func newSeasonalReadException(_ code: String, label: String) -> SeasonalReadException {
        return SeasonalReadException(
            code: code,
            label: label,
            minimum: 0.0,
            retries: 0,
            revision: 0,
            ceiling: 0.0,
            notes: "",
            bed: "",
            country: "",
            margin: 0.0,
            copay: 0.0,
            status: SeasonalReadExceptionStatus.created
        )
    }
}
