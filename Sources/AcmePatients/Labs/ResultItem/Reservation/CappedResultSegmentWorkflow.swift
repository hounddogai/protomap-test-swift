import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped result segments through their life cycle and keeps a journal of what it did.
    final class CappedResultSegmentService {
        var store: any CappedResultSegmentStore
        var validator: CappedResultSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedResultSegmentEngine

        init(store: any CappedResultSegmentStore, validator: CappedResultSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedResultSegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped result segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedResultSegmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped result segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedResultSegmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped result segment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCappedResultSegmentService(_ store: any CappedResultSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedResultSegmentService {
        return CappedResultSegmentService(
            store: store,
            validator: defaultCappedResultSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedResultSegmentEngine(flags)
        )
    }
}
