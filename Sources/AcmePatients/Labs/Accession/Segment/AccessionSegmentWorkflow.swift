import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession segments through their life cycle and keeps a journal of what it did.
    final class AccessionSegmentCoordinator {
        var store: any AccessionSegmentStore
        var validator: AccessionSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AccessionSegmentEngine

        init(store: any AccessionSegmentStore, validator: AccessionSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AccessionSegmentEngine) {
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
                throw Kit.Failure("accession segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionSegmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionSegmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession segment \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAccessionSegmentCoordinator(_ store: any AccessionSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AccessionSegmentCoordinator {
        return AccessionSegmentCoordinator(
            store: store,
            validator: defaultAccessionSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultAccessionSegmentEngine(flags)
        )
    }
}
