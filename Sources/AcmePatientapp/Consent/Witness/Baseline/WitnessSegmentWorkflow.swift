import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness segments through their life cycle and keeps a journal of what it did.
    final class WitnessSegmentCoordinator {
        var store: any WitnessSegmentStore
        var validator: WitnessSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WitnessSegmentStore, validator: WitnessSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("witness segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessSegmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessSegmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newWitnessSegmentCoordinator(_ store: any WitnessSegmentStore, clock: any Kit.Clocks.Clock) -> WitnessSegmentCoordinator {
        return WitnessSegmentCoordinator(
            store: store,
            validator: defaultWitnessSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
