import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation segments through their life cycle and keeps a journal of what it did.
    final class IsolationSegmentDesk {
        var store: any IsolationSegmentStore
        var validator: IsolationSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: IsolationSegmentEngine

        init(store: any IsolationSegmentStore, validator: IsolationSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: IsolationSegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationSegmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationSegmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation segment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newIsolationSegmentDesk(_ store: any IsolationSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> IsolationSegmentDesk {
        return IsolationSegmentDesk(
            store: store,
            validator: defaultIsolationSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultIsolationSegmentEngine(flags)
        )
    }
}
