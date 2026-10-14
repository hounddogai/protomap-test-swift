import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves default dispense manifests through their life cycle and keeps a journal of what it did.
    final class DefaultDispenseManifestWorkflow {
        var store: any DefaultDispenseManifestStore
        var validator: DefaultDispenseManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultDispenseManifestStore, validator: DefaultDispenseManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("default dispense manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultDispenseManifestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default dispense manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultDispenseManifestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newDefaultDispenseManifestWorkflow(_ store: any DefaultDispenseManifestStore, clock: any Kit.Clocks.Clock) -> DefaultDispenseManifestWorkflow {
        return DefaultDispenseManifestWorkflow(
            store: store,
            validator: defaultDefaultDispenseManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
