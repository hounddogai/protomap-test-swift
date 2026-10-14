import AcmePlatform
import Foundation

extension Labs {
    /// Moves default reference range segments through their life cycle and keeps a journal of what it did.
    final class DefaultReferenceRangeSegmentService {
        var store: any DefaultReferenceRangeSegmentStore
        var validator: DefaultReferenceRangeSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultReferenceRangeSegmentStore, validator: DefaultReferenceRangeSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default reference range segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultReferenceRangeSegmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default reference range segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultReferenceRangeSegmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newDefaultReferenceRangeSegmentService(_ store: any DefaultReferenceRangeSegmentStore, clock: any Kit.Clocks.Clock) -> DefaultReferenceRangeSegmentService {
        return DefaultReferenceRangeSegmentService(
            store: store,
            validator: defaultDefaultReferenceRangeSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
